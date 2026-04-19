import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class NutritionScanResult {
  final double? kcal;
  final double? protein;
  final double? carbs;
  final double? fat;
  final String? productName;
  final String rawText;

  const NutritionScanResult({
    this.kcal,
    this.protein,
    this.carbs,
    this.fat,
    this.productName,
    required this.rawText,
  });

  bool get isFromBarcode => productName != null;
  bool get hasAnyValue =>
      kcal != null || protein != null || carbs != null || fat != null;
  int get foundCount =>
      [kcal, protein, carbs, fat].where((v) => v != null).length;
}

class _Line {
  final String raw;
  final String norm;
  final double cx, cy;
  final double left, right, top, bottom;

  const _Line({
    required this.raw,
    required this.norm,
    required this.cx,
    required this.cy,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
  });

  double get height => bottom - top;
  double get width => right - left;
}

class LabelScannerService {
  static const _offHeaders = {
    'User-Agent': 'GymOS/1.0 (Flutter; contact@gymos.app)',
    'Accept': 'application/json',
  };

  final _picker = ImagePicker();

  // ─── Smart scan: barcode first, OCR fallback ────────────────────────────

  Future<NutritionScanResult?> scanFromCamera() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (photo == null) return null;
    return _processSmart(File(photo.path));
  }

  Future<NutritionScanResult?> scanFromGallery() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );
    if (photo == null) return null;
    return _processSmart(File(photo.path));
  }

  Future<NutritionScanResult?> scanBarcodeFromGallery() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );
    if (photo == null) return null;
    return _tryBarcode(File(photo.path));
  }

  Future<NutritionScanResult> _processSmart(File image) async {
    // 1. Tenta barcode → lookup Open Food Facts
    final barcodeResult = await _tryBarcode(image);
    if (barcodeResult != null) return barcodeResult;

    // 2. Fallback: OCR da tabela nutricional
    return _processOcr(image);
  }

  Future<NutritionScanResult?> _tryBarcode(File image) async {
    // BarcodeScanner() sem argumentos usa BarcodeFormat.all por defeito.
    final scanner = BarcodeScanner();
    try {
      final barcodes = await scanner.processImage(InputImage.fromFile(image));
      debugPrint('[Scanner] Barcodes encontrados: ${barcodes.length}');

      // Prefere EAN/UPC (numérico puro). QR codes em embalagens são quase
      // sempre URLs de marketing — não servem para lookup no OFF.
      final eanCode = barcodes
          .where((b) => b.rawValue != null)
          .where((b) => RegExp(r'^\d{6,14}$').hasMatch(b.rawValue!))
          .map((b) => b.rawValue!)
          .firstOrNull;

      if (eanCode != null) {
        debugPrint('[Scanner] Código numérico: $eanCode');
        return lookupBarcode(eanCode);
      }

      debugPrint('[Scanner] Nenhum código numérico válido (${barcodes.map((b) => b.rawValue).toList()})');
      return null;
    } catch (e) {
      debugPrint('[Scanner] Erro barcode: $e');
      return null;
    } finally {
      scanner.close();
    }
  }

  Future<NutritionScanResult?> lookupBarcode(String barcode) async {
    try {
      final uri = Uri.https(
        'world.openfoodfacts.org',
        '/api/v2/product/$barcode.json',
        {'fields': 'product_name,brands,nutriments'},
      );
      final response = await http
          .get(uri, headers: _offHeaders)
          .timeout(const Duration(seconds: 12));

      debugPrint('[Scanner] OFF HTTP ${response.statusCode} para $barcode');
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'];
      debugPrint('[Scanner] OFF status=$status');
      // v2: status=1 (found) / v3: status="product found"
      final found = status == 1 || status == '1' || status == 'product found';
      if (!found) return null;

      final product = data['product'] as Map<String, dynamic>;
      final nutriments = product['nutriments'] as Map<String, dynamic>?;
      if (nutriments == null) return null;

      String name = ((product['product_name'] as String?) ?? '').trim();
      final brands = ((product['brands'] as String?) ?? '').trim();
      if (name.isEmpty) name = brands;
      if (brands.isNotEmpty &&
          name.isNotEmpty &&
          !name.toLowerCase().contains(brands.toLowerCase())) {
        name = '$name ($brands)';
      }

      final kcal = _toDouble(
          nutriments['energy-kcal_100g'] ?? nutriments['energy-kcal']);
      final protein =
          _toDouble(nutriments['proteins_100g'] ?? nutriments['proteins']);
      final carbs = _toDouble(
          nutriments['carbohydrates_100g'] ?? nutriments['carbohydrates']);
      final fat = _toDouble(nutriments['fat_100g'] ?? nutriments['fat']);

      debugPrint('[Scanner] OFF → $name  kcal=$kcal P=$protein C=$carbs F=$fat');

      return NutritionScanResult(
        kcal: kcal > 0 ? kcal : null,
        protein: protein > 0 ? protein : null,
        carbs: carbs > 0 ? carbs : null,
        fat: fat > 0 ? fat : null,
        productName: name.isNotEmpty ? name : null,
        rawText: barcode,
      );
    } catch (e) {
      debugPrint('[Scanner] Barcode lookup error: $e');
      return null;
    }
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  Future<NutritionScanResult> _processOcr(File image) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFile(image);
      final recognized = await recognizer.processImage(inputImage);

      final positional = _parseByPosition(recognized);
      debugPrint('[Scanner] positional found ${positional.foundCount}/4');

      NutritionScanResult bestResult = positional;

      if (positional.foundCount < 3) {
        final linear = _parseLinear(recognized.text);
        debugPrint('[Scanner] linear found ${linear.foundCount}/4');
        bestResult = _merge(positional, linear, recognized.text);
      }

      return _applyMathCorrection(bestResult);
    } finally {
      recognizer.close();
    }
  }

  NutritionScanResult _merge(
      NutritionScanResult a, NutritionScanResult b, String rawText) {
    return NutritionScanResult(
      kcal: a.kcal ?? b.kcal,
      protein: a.protein ?? b.protein,
      carbs: a.carbs ?? b.carbs,
      fat: a.fat ?? b.fat,
      rawText: rawText,
    );
  }

  // ─── Prova dos 9: Brute-Force Completo sobre todos os candidatos OCR ────────

  NutritionScanResult _applyMathCorrection(NutritionScanResult result) {
    // Verificação rápida: se já está matematicamente correto, não tocar.
    if (result.kcal != null && result.carbs != null &&
        result.protein != null && result.fat != null) {
      final k = result.kcal!, c = result.carbs!, p = result.protein!, f = result.fat!;
      if ((c * 4 + p * 4 + f * 9 - k).abs() / k <= 0.10 && c + p + f <= 105) {
        return result;
      }
    }

    final allNums = _extractAllCandidates(result.rawText);

    // Candidatos de kcal: usar o já encontrado se existir; senão tentar 50–950.
    final kcalCandidates = (result.kcal != null && result.kcal! > 0)
        ? [result.kcal!]
        : allNums.where((v) => v >= 50 && v < 950).toList();

    // Candidatos de macros: qualquer valor entre 0 e 100 g.
    final macros = allNums.where((v) => v > 0 && v <= 100).toList();

    if (kcalCandidates.isEmpty || macros.isEmpty) return result;

    // Valores originais do scanner para o tiebreaker de proximidade.
    final origF = result.fat, origC = result.carbs, origP = result.protein;

    double bestScore = double.infinity;
    double bestRelErr = 0.15;
    double? bestKcal, bestC, bestP, bestF;

    for (final k in kcalCandidates) {
      for (final f in macros) {
        if (f * 9 > k * 1.05) continue;
        for (final c in macros) {
          if (c + f > 108) continue;
          if (c * 4 + f * 9 > k * 1.05) continue;
          for (final p in macros) {
            if (c + p + f > 108) continue;
            final calc = c * 4 + p * 4 + f * 9;
            final relErr = (calc - k).abs() / k;
            if (relErr >= 0.15) continue;

            // Penalização proporcional ao afastamento dos valores originais:
            // garante que soluções espúrias com math quase-perfeito não vencem
            // quando os valores originais já são razoavelmente correctos.
            double proximity = 0;
            if (origF != null && origF > 0) proximity += (f - origF).abs() / origF;
            if (origC != null && origC > 0) proximity += (c - origC).abs() / origC;
            if (origP != null && origP > 0) proximity += (p - origP).abs() / origP;

            final score = relErr + proximity * 0.05;
            if (score < bestScore) {
              bestScore = score;
              bestRelErr = relErr;
              bestKcal = k; bestC = c; bestP = p; bestF = f;
            }
          }
        }
      }
    }

    if (bestKcal != null) {
      debugPrint(
        '[Scanner] MathFix → kcal=$bestKcal C=$bestC P=$bestP F=$bestF '
        'err=${(bestRelErr * 100).toStringAsFixed(1)}%',
      );
      return NutritionScanResult(
        kcal: bestKcal, protein: bestP, carbs: bestC, fat: bestF,
        rawText: result.rawText,
      );
    }

    return result;
  }

  /// Extrai todos os valores numéricos únicos do texto OCR bruto.
  List<double> _extractAllCandidates(String rawText) {
    final norm = _fixOcrErrors(_normalize(rawText));
    final seen = <double>{};
    for (final m in RegExp(r'\d+[,.]\d+|\d+').allMatches(norm)) {
      final v = double.tryParse(m.group(0)!.replaceAll(',', '.'));
      if (v != null) seen.add(v);
    }
    return seen.toList();
  }

  // ─── Strategy 1: Positional (Grid-Aware) ────────────────────────────────

  NutritionScanResult _parseByPosition(RecognizedText recognized) {
    final lines = <_Line>[];
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final b = line.boundingBox;
        lines.add(_Line(
          raw: line.text,
          norm: _fixOcrErrors(_normalize(line.text)),
          cx: (b.left + b.right) / 2.0,
          cy: (b.top + b.bottom) / 2.0,
          left: b.left.toDouble(),
          right: b.right.toDouble(),
          top: b.top.toDouble(),
          bottom: b.bottom.toDouble(),
        ));
      }
    }
    if (lines.isEmpty) return NutritionScanResult(rawText: recognized.text);

    final per100gCx = _detectColumnX(lines, _kPer100gHeaders);
    final valueLines = lines.where((l) {
      if (!_hasNumericValue(l.norm)) return false;
      final clean = l.norm.trim();
      if (clean == '100g' || clean == '100 g' || clean == '100ml' || clean == '100 ml') return false;
      return true;
    }).toList();

    double? matchMacro(List<String> keywords) {
      for (final kw in keywords) {
        _Line? labelLine;
        for (final l in lines) {
          if (_isPrimaryLabelMatch(l.norm, kw)) {
            // Ignora linhas de ingredientes: ficam à DIREITA do per100g (ex: "gordura de palma")
            if (per100gCx != null && l.cx > per100gCx + 50) continue;
            labelLine = l;
            break;
          }
        }
        if (labelLine == null) continue;

        final inline = _firstGrams(labelLine.norm, allowUnitless: false);
        if (inline != null) return inline;

        double bestScore = double.infinity;
        double? bestVal;
        final rowH = labelLine.height.clamp(12.0, 60.0);
        final nextSubLabel = _findNearestSubValueLineBelow(lines, labelLine);
        // Usa o bottom da sub-label (não o ponto médio) para dar espaço ao valor
        // da linha principal quando a imagem está inclinada.
        final subLabelCutoffY = nextSubLabel?.bottom;

        for (final vl in valueLines) {
          if (vl == labelLine) continue;
          if (_isSubValue(vl.norm)) continue;

          final yDist = (vl.cy - labelLine.cy).abs();
          final xOffset = vl.cx - labelLine.cx; 

          if (yDist > rowH * 3.5) continue;
          if (subLabelCutoffY != null && vl.cy > subLabelCutoffY) continue;

          double score = yDist * 5.0; 
          
          if (per100gCx != null) {
            double xDistFrom100g = (vl.cx - per100gCx).abs();
            score += xDistFrom100g * 2.0; 
            if (xDistFrom100g < 100) {
              score -= 2000;
            }
          } else {
            if (xOffset > 0) {
              score += xOffset;
            } else {
              score += xOffset.abs() * 10.0;
            }
          }

          // O TIE-BREAKER: Desempata escolhendo sempre o valor que está mais acima
          // Impede que roube valores dos sub-nutrientes que estão impressos abaixo.
          score += vl.cy * 0.1;

          if (score < bestScore) {
            final v = _extractCleanNumber(vl.norm);
            if (v != null) {
              bestScore = score;
              bestVal = v;
            }
          }
        }
        if (bestVal != null) return bestVal;
      }
      return null;
    }

    double? matchKcal() {
      _Line? bestInline;
      double bestInlineScore = double.infinity;
      
      for (final l in lines) {
        final v = _extractKcal(l.norm, allowUnitless: false);
        if (v != null && v < 950) {
          double score = l.cx;
          if (per100gCx != null) {
            score = (l.cx - per100gCx).abs();
          }
          if (score < bestInlineScore) {
            bestInlineScore = score;
            bestInline = l;
          }
        }
      }
      
      if (bestInline != null) {
        return _extractKcal(bestInline.norm, allowUnitless: false);
      }

      _Line? labelLine;
      for (final l in lines) {
        if (_kEnergyKeywords.any((kw) => l.norm.contains(kw)) || l.norm.contains('kcal')) {
          if (!_isSubValue(l.norm)) {
            labelLine = l;
            break;
          }
        }
      }
      if (labelLine == null) return null;

      double bestScore = double.infinity;
      double? bestVal;
      final rowH = labelLine.height.clamp(12.0, 60.0);

      for (final vl in valueLines) {
        if (vl == labelLine) continue;
        if (_isSubValue(vl.norm)) continue;
        if (vl.norm.contains('kj') && !vl.norm.contains('kcal')) continue;

        final v = _extractCleanNumber(vl.norm);
        if (v == null) continue;
        if (v > 950) continue;

        final yDist = (vl.cy - labelLine.cy).abs();
        final xOffset = vl.cx - labelLine.cx;

        if (yDist > rowH * 3.5) continue;

        double score = yDist * 5.0;
        
        if (per100gCx != null) {
          double xDistFrom100g = (vl.cx - per100gCx).abs();
          score += xDistFrom100g * 2.0;
          if (xDistFrom100g < 100) {
            score -= 2000;
          }
        } else {
          if (xOffset > 0) {
            score += xOffset;
          } else {
            score += xOffset.abs() * 10.0;
          }
        }

        if (vl.norm.contains('kcal')) {
          score -= 1000;
        }
        
        // Tie-breaker para calorias também, just in case
        score += vl.cy * 0.1;

        if (score < bestScore) {
          bestScore = score;
          bestVal = v;
        }
      }
      return bestVal;
    }

    return NutritionScanResult(
      kcal: matchKcal(),
      protein: matchMacro(_kProtein),
      carbs: matchMacro(_kCarbs),
      fat: matchMacro(_kFat),
      rawText: recognized.text,
    );
  }

  // ─── Column detection ────────────────────────────────────────────────────

  double? _detectColumnX(List<_Line> lines, List<String> patterns) {
    for (final p in patterns) {
      for (final l in lines) {
        if (l.norm.contains(p)) return l.cx;
      }
    }
    return null;
  }

  // ─── Strategy 2: Linear Text Scan ────────────────────────────────────────

  NutritionScanResult _parseLinear(String rawText) {
    final norm = _fixOcrErrors(_normalize(rawText));
    final allMacroKw = [..._kProtein, ..._kCarbs, ..._kFat, ..._kEnergyKeywords];

    double? findMacro(List<String> keywords) {
      for (final kw in keywords) {
        int from = 0;
        while (true) {
          final idx = norm.indexOf(kw, from);
          if (idx == -1) break;
          final ls = norm.lastIndexOf('\n', idx);
          final le = norm.indexOf('\n', idx);
          final line = norm.substring(ls < 0 ? 0 : ls + 1, le < 0 ? norm.length : le);

          if (_isPrimaryLabelMatch(line, kw)) {
            final searchStart = idx + kw.length;
            var searchEnd = (searchStart + 300).clamp(0, norm.length);
            final searchZone = norm.substring(searchStart, searchEnd);
            for (final other in allMacroKw) {
              if (other == kw) continue;
              final oi = searchZone.indexOf(other);
              if (oi > 5) {
                searchEnd = (searchStart + oi).clamp(searchStart, searchEnd);
                break;
              }
            }
            final val = _extractCleanNumber(norm.substring(searchStart, searchEnd));
            if (val != null) return val;
          }
          from = idx + 1;
        }
      }
      return null;
    }

    double? kcal;
    final combined = RegExp(r'\d+[,.]?\d*\s*kj\s*[/\\|]\s*(\d+[,.]?\d*)\s*kcal').firstMatch(norm);
    if (combined != null) {
      kcal = double.tryParse(combined.group(1)!.replaceAll(',', '.'));
    }
    if (kcal == null) {
      final simple = RegExp(r'(\d+[,.]?\d*)\s*kcal').firstMatch(norm);
      if (simple != null) kcal = double.tryParse(simple.group(1)!.replaceAll(',', '.'));
    }

    return NutritionScanResult(
      kcal: kcal,
      protein: findMacro(_kProtein),
      carbs: findMacro(_kCarbs),
      fat: findMacro(_kFat),
      rawText: rawText,
    );
  }

  // ─── Keywords ────────────────────────────────────────────────────────────

  static const _kPer100gHeaders = [
    '/100g', '/100 g', 'per 100g', 'per 100 g',
    'por 100g', 'por 100 g', 'pour 100g', 'pour 100 g', 'pro 100g',
    'for 100g', '100g', '100 g', '100ml', '100 ml'
  ];

  static const _kEnergyKeywords = [
    'valor energetico', 'energia', 'energie', 'energy', 'valeur energetique',
    'valore energetico', 'valor calorico', 'calorias', 'energetica', 
    'brennwert'
  ];

  static const _kProtein = [
    'proteinas', 'proteina', 'proteines', 'proteine', 'protein', 'prote', 
    'bielkoviny', 'feherje', 'eiweiss', 'bilkoviny'
  ];

  static const _kCarbs = [
    'hidratos de carbono', 'carboidrati', 'carboidratos',
    'carbohidratos', 'carbohydrates', 'carbohydrate',
    'glucides', 'glucidos', 'glucide', 'hidratos', 'hidrats',
    'sacharidy', 'koolhydraten', 'kohlenhydrate'
  ];

  static const _kFat = [
    'gorduras totais', 'gordura total', 'lipidos totais', 'lipido total',
    'grassi totali', 'grasas totales', 'matiere grasse', 'matieres grasses', 'lipides totaux',
    'gorduras', 'gordura', 'lipidos', 'lipido',
    'grasa', 'grasimi', 'fats', 'fat', 'tuky', 'zsir', 'vet', 'fett', 'maznini'
  ];

  static const _kSubValues = [
    'acucares', 'acucar', 'zuccheri', 'sugar', 'azucares', 'cukrok', 'cukry', 'sucres', 'sucies',
    'saturad', 'saturi', 'di cui', 'dos quais', 'das quais', 'din care',
    'de los cuales', 'of which', 'dont les', 'dont', 'z toho', 'saures',
    'fibra', 'fiber', 'fibre', 'fibras',
    'sodio', 'sodium', ' sal', 'sare', 'sol', 'sel',
    'monoinsaturad', 'polinsaturad', 'trans',
    'omega', 'vitamina', 'vitamin', 'calcio', 'ferro', 'magnesio',
  ];

  // ─── Helpers ─────────────────────────────────────────────────────────────

  bool _hasNumericValue(String norm) {
    final lettersOnly = norm.replaceAll(RegExp(r'[^a-z]'), '');
    if (lettersOnly.length < 6 && RegExp(r'\d').hasMatch(norm)) return true;
    if (RegExp(r'\d+[,.]?\d*\s*(?:g|mg|µg|ug|kcal|kj)\b').hasMatch(norm)) return true;
    return false;
  }

  bool _isSubValue(String norm) => _kSubValues.any((s) => norm.contains(s));

  _Line? _findNearestSubValueLineBelow(List<_Line> lines, _Line anchor) {
    _Line? best;
    double bestDistance = double.infinity;

    for (final line in lines) {
      if (!_isSubValue(line.norm)) continue;
      if (line.cy <= anchor.cy) continue;

      final distance = line.cy - anchor.cy;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = line;
      }
    }

    return best;
  }

  bool _isPrimaryLabelMatch(String norm, String keyword) {
    final keywordIndex = norm.indexOf(keyword);
    if (keywordIndex == -1) return false;

    int? firstSubIndex;
    for (final sub in _kSubValues) {
      final idx = norm.indexOf(sub);
      if (idx == -1) continue;
      if (firstSubIndex == null || idx < firstSubIndex) {
        firstSubIndex = idx;
      }
    }

    if (firstSubIndex == null) return true;
    return keywordIndex <= firstSubIndex;
  }

  double? _extractCleanNumber(String text) {
    final matches = RegExp(r'(\d+[,.]\d+|\d+)').allMatches(text).toList();
    if (matches.isEmpty) return null;

    if (matches.length > 1 && text.contains('(0') && matches.first.group(1) == '0') {
      return double.tryParse(matches[1].group(1)!.replaceAll(',', '.'));
    }

    if (matches.length >= 2 && text.contains('/')) {
      final v1 = double.tryParse(matches[0].group(1)!.replaceAll(',', '.'));
      final v2 = double.tryParse(matches[1].group(1)!.replaceAll(',', '.'));
      if (v1 != null && v2 != null) {
        return v1 < v2 ? v1 : v2;
      }
    }

    return double.tryParse(matches.first.group(1)!.replaceAll(',', '.'));
  }

  double? _firstGrams(String text, {bool allowUnitless = false}) {
    for (final m in RegExp(r'(\d+[,.]\d+|\d+)\s*g(?!\w)').allMatches(text)) {
      final v = double.tryParse(m.group(1)!.replaceAll(',', '.'));
      if (v != null && v < 1000) return v;
    }
    if (allowUnitless && RegExp(r'^\s*\d+[,.]?\d*\s*$').hasMatch(text)) {
      final v = double.tryParse(text.trim().replaceAll(',', '.'));
      if (v != null && v < 1000) return v;
    }
    return null;
  }

  double? _extractKcal(String text, {bool allowUnitless = false}) {
    final combined = RegExp(
      r'\d+[,.]?\d*\s*kj\s*[/\\|]\s*(\d+[,.]?\d*)\s*kcal',
    ).firstMatch(text);
    if (combined != null) {
      return double.tryParse(combined.group(1)!.replaceAll(',', '.'));
    }

    // Linha com cabeçalho "(kJ/kcal)" e par de valores "2360 / 566" na mesma linha OCR
    if (text.contains('kj') || text.contains('kcal')) {
      final pair = RegExp(r'(\d{3,})\s*/\s*(\d{2,3})').firstMatch(text);
      if (pair != null) {
        final v1 = double.tryParse(pair.group(1)!);
        final v2 = double.tryParse(pair.group(2)!);
        if (v1 != null && v2 != null && v2 < v1 && v2 < 950 && v2 > 0) return v2;
      }
    }
    
    final simple = RegExp(r'(\d+[,.]?\d*)\s*kcal').firstMatch(text);
    if (simple != null) {
      return double.tryParse(simple.group(1)!.replaceAll(',', '.'));
    }
    
    final reverse = RegExp(r'kcal[^0-9]*(\d+[,.]?\d*)').firstMatch(text);
    if (reverse != null) {
      return double.tryParse(reverse.group(1)!.replaceAll(',', '.'));
    }

    if (allowUnitless && RegExp(r'^\s*\d+[,.]?\d*\s*$').hasMatch(text)) {
      return double.tryParse(text.trim().replaceAll(',', '.'));
    }
    return null;
  }

  String _fixOcrErrors(String text) {
    return text
        .replaceAll('100 9', '100g')
        .replaceAll('1009', '100g')
        .replaceAll('kW', 'kJ').replaceAll('KW', 'KJ').replaceAll('kw', 'kj')
        .replaceAllMapped(RegExp(r'\bO([,.]?\d)'), (m) => '0${m.group(1)}')
        .replaceAllMapped(RegExp(r'\bl(\d)'), (m) => '1${m.group(1)}')
        // "37,39" → "37,3g": 9 colado a decimal de 1 casa é quase sempre um "g" mal lido.
        // Tem de vir ANTES da regra seguinte para evitar que \d+[,.]\d+ engula o 9.
        .replaceAllMapped(RegExp(r'(\d+[,.]\d)9\b'), (m) => '${m.group(1)}g')
        // Trata os malditos espaços antes do "9" que era suposto ser um "g"
        .replaceAllMapped(RegExp(r'\b(\d+[,.]\d+)\s*9\b'), (m) => '${m.group(1)}g')
        .replaceAllMapped(RegExp(r'\b(\d{2,})\s*9\b'), (m) => '${m.group(1)}g')
        .replaceAllMapped(RegExp(r'(\d)s\b'), (m) => '${m.group(1)}g')
        .replaceAllMapped(RegExp(r'(\d)a\b'), (m) => '${m.group(1)}g');
  }

  String _normalize(String text) => text
      .toLowerCase()
      .replaceAll('é', 'e').replaceAll('è', 'e').replaceAll('ê', 'e')
      .replaceAll('á', 'a').replaceAll('à', 'a').replaceAll('â', 'a').replaceAll('ã', 'a')
      .replaceAll('í', 'i').replaceAll('ì', 'i').replaceAll('î', 'i').replaceAll('ï', 'i')
      .replaceAll('ó', 'o').replaceAll('ò', 'o').replaceAll('ô', 'o').replaceAll('õ', 'o')
      .replaceAll('ú', 'u').replaceAll('ù', 'u').replaceAll('û', 'u').replaceAll('ü', 'u')
      .replaceAll('ç', 'c').replaceAll('ñ', 'n').replaceAll('ă', 'a').replaceAll('ț', 't').replaceAll('ș', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('\r', '');
      
}
