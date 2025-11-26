// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart';
import '/custom_code/actions/index.dart';
import '/flutter_flow/custom_functions.dart';
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

class Prospectailanding extends StatefulWidget {
  const Prospectailanding({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<Prospectailanding> createState() => _ProspectailandingState();
}

class _ProspectailandingState extends State<Prospectailanding> {
  final TextEditingController urlController = TextEditingController();
  int selectedQuantity = 100;
  bool isLoading = false;
  bool showError = false;
  String errorMessage = '';
  int? companyId;
  String? userId;

  bool showModal = false;
  String modalState = 'loading';
  int currentCount = 0;
  int extractedCount = 0;
  Timer? counterTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
    urlController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    urlController.dispose();
    counterTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final user = SupaFlow.client.auth.currentUser;
      if (user != null) {
        userId = user.id;

        final userData = await SupaFlow.client
            .from('users')
            .select('company_id')
            .eq('auth_user_id', userId!)
            .single();

        if (mounted) {
          setState(() {
            companyId = userData['company_id'] as int?;
          });
        }
      }
    } catch (e) {
      print('⚠️ Aviso ao buscar company_id: $e');
    }
  }

  bool _isValidGoogleMapsUrl(String url) {
    return url.contains('google.com/maps') && url.length > 30;
  }

  void _showErrorMessage(String message) {
    setState(() {
      showError = true;
      errorMessage = message;
    });
  }

  void _clearError() {
    setState(() {
      showError = false;
      errorMessage = '';
    });
  }

  void _startCounter(int target) {
    currentCount = 0;
    const duration = Duration(milliseconds: 50);
    final increment = target / 40;

    counterTimer = Timer.periodic(duration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        currentCount += increment.round();
        if (currentCount >= target) {
          currentCount = target;
          timer.cancel();
        }
      });
    });
  }

  void _stopCounter() {
    counterTimer?.cancel();
  }

  void _showExtractionModal(String state, {int? count, String? message}) {
    setState(() {
      showModal = true;
      modalState = state;
      if (count != null) extractedCount = count;
      if (message != null) errorMessage = message;
    });
  }

  void _closeModal() {
    setState(() {
      showModal = false;
      currentCount = 0;
    });
  }

  Future<void> _startExtraction() async {
    final url = urlController.text.trim();

    if (url.isEmpty) {
      _showErrorMessage('Por favor, insira uma URL');
      return;
    }

    if (!_isValidGoogleMapsUrl(url)) {
      _showErrorMessage('URL inválida. Use uma URL válida do Google Maps');
      return;
    }

    if (companyId == null) {
      _showErrorMessage('Erro ao identificar empresa. Faça login novamente.');
      return;
    }

    _clearError();
    setState(() => isLoading = true);

    _showExtractionModal('loading');
    _startCounter(selectedQuantity);

    try {
      const webhookUrl =
          'https://vendai-n8n.aw5nou.easypanel.host/webhook/extrair-leads';

      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'startUrls': [
            {'url': url}
          ],
          'company_id': companyId,
          'quantity': selectedQuantity,
        }),
      );

      _stopCounter();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          _showExtractionModal(
            'success',
            count: data['extractedCount'] ?? selectedQuantity,
          );
        } else {
          _showExtractionModal(
            'error',
            message: data['message'] ?? 'Erro ao extrair leads',
          );
        }
      } else {
        _showExtractionModal(
          'error',
          message: 'Erro na requisição. Tente novamente.',
        );
      }
    } catch (e) {
      _stopCounter();
      _showExtractionModal(
        'error',
        message: 'Erro de conexão. Verifique sua internet.',
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _navigateToLeads() {
    context.pushNamed('crm');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;
    final hasValidUrl = urlController.text.isNotEmpty &&
        _isValidGoogleMapsUrl(urlController.text);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF0a0a0a),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: isMobile ? 40 : 60),
                  child: Text(
                    'prospect.AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 24 : 32,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 900),
                      padding:
                          EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildHeroSection(isMobile),
                          SizedBox(height: isMobile ? 40 : 60),
                          _buildFormSection(isMobile, hasValidUrl),
                          SizedBox(height: isMobile ? 40 : 60),
                          _buildFeatures(isMobile),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showModal) _buildModal(isMobile),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isMobile) {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 28 : 48,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            children: const [
              TextSpan(text: 'O jeito mais '),
              TextSpan(
                text: 'rápido',
                style: TextStyle(color: Color(0xFFFF9500)),
              ),
              TextSpan(
                  text: ' de transformar\nbuscas em oportunidades reais.'),
            ],
          ),
        ),
        SizedBox(height: isMobile ? 16 : 24),
        Text(
          'Transforme qualquer busca do Google Maps em leads qualificados.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFFa0a0a0),
            fontSize: isMobile ? 14 : 18,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection(bool isMobile, bool hasValidUrl) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 900),
      child: Column(
        children: [
          isMobile
              ? Column(
                  children: [
                    _buildUrlInput(),
                    const SizedBox(height: 12),
                    _buildQuantityDropdown(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildUrlInput()),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 160,
                      child: _buildQuantityDropdown(),
                    ),
                  ],
                ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (hasValidUrl && !isLoading) ? _startExtraction : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasValidUrl
                    ? const Color(0xFFFF9500)
                    : const Color(0xFF2a2a2a),
                disabledBackgroundColor: const Color(0xFF2a2a2a),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'Extrair leads',
                style: TextStyle(
                  color: hasValidUrl ? Colors.white : const Color(0xFF666666),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a1a),
            border: Border.all(
              color:
                  showError ? const Color(0xFFFF3B30) : const Color(0xFF2a2a2a),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: urlController,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'Courier New',
            ),
            decoration: const InputDecoration(
              hintText: 'https://www.google.com/maps/search/...',
              hintStyle: TextStyle(color: Color(0xFF555555), fontSize: 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 48,
                vertical: 16,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: 16, right: 12),
                child: Icon(
                  Icons.link,
                  color: Color(0xFF666666),
                  size: 18,
                ),
              ),
              prefixIconConstraints: BoxConstraints(minWidth: 48),
            ),
            onChanged: (value) => _clearError(),
          ),
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              errorMessage,
              style: const TextStyle(
                color: Color(0xFFFF3B30),
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuantityDropdown() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        border: Border.all(color: const Color(0xFF2a2a2a)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedQuantity,
          isExpanded: true,
          dropdownColor: const Color(0xFF1a1a1a),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          icon:
              const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
          items: [50, 100, 150, 200, 250, 300].map((int value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text('$value leads'),
            );
          }).toList(),
          onChanged: (int? newValue) {
            if (newValue != null) {
              setState(() => selectedQuantity = newValue);
            }
          },
        ),
      ),
    );
  }

  Widget _buildFeatures(bool isMobile) {
    return Column(
      children: [
        SizedBox(height: isMobile ? 20 : 24),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 900),
          child: isMobile
              ? Column(
                  children: [
                    _buildFeatureCard(
                      Icons.bolt,
                      'Extrai dados de Google Maps automaticamente com IA em segundos.',
                    ),
                    const SizedBox(height: 20),
                    _buildFeatureCard(
                      Icons.description_outlined,
                      'Captura nome, telefone, email, endereço e redes sociais em um clique.',
                    ),
                    const SizedBox(height: 20),
                    _buildFeatureCard(
                      Icons.people_outline,
                      'Leads organizados e qualificados direto no seu pipeline de vendas.',
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildFeatureCard(
                        Icons.bolt,
                        'Extrai dados de Google Maps automaticamente com IA em segundos.',
                      ),
                    ),
                    const SizedBox(width: 30),
                    Expanded(
                      child: _buildFeatureCard(
                        Icons.description_outlined,
                        'Captura nome, telefone, email, endereço e redes sociais em um clique.',
                      ),
                    ),
                    const SizedBox(width: 30),
                    Expanded(
                      child: _buildFeatureCard(
                        Icons.people_outline,
                        'Leads organizados e qualificados direto no seu pipeline de vendas.',
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        border: Border.all(color: const Color(0xFF2a2a2a)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF0a0a0a),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFF9500),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModal(bool isMobile) {
    return GestureDetector(
      onTap: modalState != 'loading' ? _closeModal : null,
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: isMobile ? MediaQuery.of(context).size.width * 0.9 : 500,
              padding: EdgeInsets.all(isMobile ? 40 : 60),
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a1a),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2a2a2a)),
              ),
              child: modalState == 'loading'
                  ? _buildLoadingState()
                  : modalState == 'success'
                      ? _buildSuccessState(isMobile)
                      : _buildErrorState(isMobile),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFFFF9500),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          'Extraindo leads...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '$currentCount',
          style: const TextStyle(
            color: Color(0xFFFF9500),
            fontSize: 56,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Processando sua solicitação',
          style: TextStyle(
            color: Color(0xFF888888),
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState(bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFF34C759),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          'Sucesso! 🎉',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Você extraiu $extractedCount leads com sucesso.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF888888),
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 32),
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  _closeModal();
                  _navigateToLeads();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9500),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Abrir Tabela de Leads',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _closeModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2a2a2a),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Fechar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorState(bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFFFF3B30),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          'Erro na Extração',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          errorMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF888888),
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _closeModal,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2a2a2a),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Fechar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
