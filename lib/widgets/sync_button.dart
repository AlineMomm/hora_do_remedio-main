import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sync_service.dart';
import '../services/settings_service.dart';
import '../pages/cloud_login_page.dart';

class SyncButton extends StatefulWidget {
  final VoidCallback onSyncComplete;
  
  const SyncButton({
    super.key,
    required this.onSyncComplete,
  });

  @override
  State<SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<SyncButton> {
  final SyncService _syncService = SyncService();
  bool _isSyncing = false;

  Future<void> _handleSyncPress() async {
    final status = await _syncService.getSyncStatus();
    
    if (!status['hasInternet']) {
      _showMessage(
        'Sem conexão',
        'Você precisa estar conectado à internet para sincronizar.',
        Icons.wifi_off,
      );
      return;
    }

    if (status['isLoggedIn']) {
      _showSyncDialog();
    } else {
      _showLoginOptions();
    }
  }

  void _showLoginOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salvar na Nuvem'),
        content: const Text(
          'Para salvar seus medicamentos online, você precisa ter uma conta.\n\n'
          'Isso permite que seus medicamentos fiquem salvos mesmo se você trocar de celular!'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Agora não'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToCloudLogin();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text('Fazer Login/Cadastro'),
          ),
        ],
      ),
    );
  }

  void _showSyncDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sincronizar com a Nuvem'),
        content: const Text(
          'Deseja sincronizar seus medicamentos com a nuvem?\n\n'
          'Isso vai enviar todos os seus dados para sua conta online.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performSync();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text('Sincronizar Agora'),
          ),
        ],
      ),
    );
  }

  Future<void> _performSync() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final cloudUserId = await _syncService.getCloudUserId();
      if (cloudUserId != null) {
        await _syncService.syncLocalToCloud(cloudUserId);
        
        if (!mounted) return;
        
        _showMessage(
          'Sucesso!',
          'Dados salvos na nuvem.',
          Icons.cloud_done,
          isSuccess: true,
        );
        
        widget.onSyncComplete();
      }
    } catch (e) {
      if (!mounted) return;
      
      _showMessage(
        'Erro',
        'Não foi possível salvar: $e',
        Icons.error,
        isSuccess: false,
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  void _showMessage(String title, String message, IconData icon, {bool isSuccess = true}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 50,
              color: isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
            ),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToCloudLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CloudLoginPage(
          onLoginSuccess: () {
            widget.onSyncComplete();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: _isSyncing ? null : _handleSyncPress,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: _isSyncing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_upload, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    'Salvar Online',
                    style: settings.getTextStyle(
                      size: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}