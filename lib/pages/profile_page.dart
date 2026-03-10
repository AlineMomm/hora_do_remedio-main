import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:convert';
import '../services/local_storage_service.dart';
import '../services/sync_service.dart';
import '../services/auth_service.dart';
import '../services/medication_service.dart';
import '../models/medication_model.dart';
import '../models/user_model.dart';
import 'medication_list_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final LocalStorageService _storage = LocalStorageService();
  final SyncService _syncService = SyncService();
  final AuthService _authService = AuthService();
  final MedicationService _medicationService = MedicationService();
  final ImagePicker _imagePicker = ImagePicker();
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;
  late TextEditingController _bloodTypeController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _observationsController;

  bool _isEditing = false;
  bool _isLoading = false;
  bool _isCloudUser = false;
  
  // Para foto de perfil
  Uint8List? _profileImageBytes;
  String? _profileImageBase64;
  bool _isImageLoading = false;
  
  final String _profileId = 'local_profile_001';
  final String _localUserId = 'local_user_001';
  
  // Dados do usuário da nuvem
  UserModel? _cloudUserData;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _checkCloudStatusAndLoadData();
  }

  // NOVO: Carregar tudo em sequência
  Future<void> _checkCloudStatusAndLoadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Primeiro verifica status da nuvem
      final status = await _syncService.getSyncStatus();
      setState(() {
        _isCloudUser = status['isLoggedIn'] ?? false;
      });

      // Depois carrega dados do usuário da nuvem se estiver logado
      if (_isCloudUser) {
        await _loadCloudUserData();
      }

      // Por fim carrega o perfil
      await _loadProfile();
      
    } catch (e) {
      print('❌ Erro ao carregar dados: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Carregar dados do usuário da nuvem
  Future<void> _loadCloudUserData() async {
    try {
      final userData = await _authService.getCurrentUser();
      if (userData != null) {
        setState(() {
          _cloudUserData = userData;
        });
        print('✅ Dados da nuvem carregados: ${userData.name}');
      }
    } catch (e) {
      print('❌ Erro ao carregar dados da nuvem: $e');
    }
  }

  // NOVA: Formatação correta de telefone
  String _formatPhoneNumber(String value) {
    // Remove tudo que não é número
    final numbers = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (numbers.isEmpty) return '';
    
    StringBuffer formatted = StringBuffer();
    
    // +55 (47) 99999-9999
    if (numbers.length >= 2) {
      formatted.write('+${numbers.substring(0, 2)}'); // +55
      
      if (numbers.length >= 4) {
        formatted.write(' (${numbers.substring(2, 4)})'); // (47)
        
        if (numbers.length >= 9) {
          formatted.write(' ${numbers.substring(4, 9)}-${numbers.substring(9, numbers.length > 13 ? 13 : numbers.length)}'); // 99999-9999
        } else if (numbers.length > 4) {
          formatted.write(' ${numbers.substring(4)}'); // 99999
        }
      } else if (numbers.length > 2) {
        formatted.write(' (${numbers.substring(2)}'); // (47 incompleto)
      }
    } else {
      formatted.write('+$numbers');
    }
    
    return formatted.toString();
  }

  // Remover formatação para salvar
  String _unformatPhoneNumber(String formatted) {
    return formatted.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _getProfile();
      
      print('📝 Carregando perfil - Nome do perfil: ${profile['name']}');
      print('📝 Carregando perfil - Nome da nuvem: ${_cloudUserData?.name}');
      
      // PRIORIDADE: Nome da nuvem primeiro, depois perfil local
      if (_cloudUserData != null && _cloudUserData!.name.isNotEmpty) {
        _nameController.text = _cloudUserData!.name;
        print('✅ Usando nome da nuvem: ${_cloudUserData!.name}');
      } else if (profile['name'] != null && profile['name'].toString().isNotEmpty) {
        _nameController.text = profile['name'];
        print('✅ Usando nome local: ${profile['name']}');
      }
      
      // Email
      _emailController.text = profile['email'] ?? _cloudUserData?.email ?? '';
      
      // Telefone - aplicar formatação
      final phone = profile['phone'] ?? '';
      if (phone.isNotEmpty) {
        _phoneController.text = _formatPhoneNumber(phone);
        print('📞 Telefone formatado: ${_phoneController.text}');
      }
      
      _ageController.text = profile['age']?.toString() ?? '';
      _bloodTypeController.text = profile['bloodType'] ?? '';
      _emergencyNameController.text = profile['emergencyContactName'] ?? '';
      
      // Telefone de emergência - aplicar formatação
      final emergencyPhone = profile['emergencyContactPhone'] ?? '';
      if (emergencyPhone.isNotEmpty) {
        _emergencyPhoneController.text = _formatPhoneNumber(emergencyPhone);
      }
      
      _observationsController.text = profile['observations'] ?? '';
      
      // Carregar foto de perfil
      if (profile['profileImage'] != null) {
        _profileImageBase64 = profile['profileImage'];
        _profileImageBytes = base64Decode(profile['profileImage']);
      }
      
    } catch (e) {
      print('❌ Erro ao carregar perfil: $e');
    }
  }

  Future<Map<String, dynamic>> _getProfile() async {
    final profiles = await _storage.getUsers();
    return profiles.firstWhere(
      (p) => p['uid'] == _profileId,
      orElse: () => {},
    );
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _ageController = TextEditingController();
    _bloodTypeController = TextEditingController();
    _emergencyNameController = TextEditingController();
    _emergencyPhoneController = TextEditingController();
    _observationsController = TextEditingController();
    
    // Listeners para formatação
    _phoneController.addListener(_formatPhoneOnChange);
    _emergencyPhoneController.addListener(_formatEmergencyPhoneOnChange);
  }

  // Formatação automática enquanto digita
  void _formatPhoneOnChange() {
    final text = _phoneController.text;
    final oldSelection = _phoneController.selection;
    
    // Só formata se não estiver apagando e tiver números
    if (text.isNotEmpty && RegExp(r'[0-9]').hasMatch(text)) {
      final unformatted = _unformatPhoneNumber(text);
      final formatted = _formatPhoneNumber(unformatted);
      
      if (formatted != text) {
        _phoneController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(
            offset: formatted.length,
          ),
        );
      }
    }
  }

  void _formatEmergencyPhoneOnChange() {
    final text = _emergencyPhoneController.text;
    
    if (text.isNotEmpty && RegExp(r'[0-9]').hasMatch(text)) {
      final unformatted = _unformatPhoneNumber(text);
      final formatted = _formatPhoneNumber(unformatted);
      
      if (formatted != text) {
        _emergencyPhoneController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(
            offset: formatted.length,
          ),
        );
      }
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _checkCloudStatusAndLoadData(); // Recarrega tudo ao cancelar
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isImageLoading = true;
    });

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        Uint8List imageBytes;
        
        if (kIsWeb) {
          imageBytes = await pickedFile.readAsBytes();
        } else {
          File imageFile = File(pickedFile.path);
          imageBytes = await imageFile.readAsBytes();
        }
        
        setState(() {
          _profileImageBytes = imageBytes;
          _profileImageBase64 = base64Encode(imageBytes);
        });
        
        print('✅ Foto selecionada com sucesso!');
      }
    } catch (e) {
      print('❌ Erro ao selecionar imagem: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar imagem: $e'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    } finally {
      setState(() {
        _isImageLoading = false;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _profileImageBytes = null;
      _profileImageBase64 = null;
    });
  }

  void _confirmRemoveImage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Remover Foto',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Tem certeza que deseja remover sua foto de perfil?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'NÃO',
                style: TextStyle(fontSize: 16, color: Color(0xFF1976D2)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _removeImage();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'SIM, REMOVER',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  // Salvar perfil
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final profile = {
          'uid': _profileId,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _unformatPhoneNumber(_phoneController.text), // Salvar sem formatação
          'age': int.tryParse(_ageController.text.trim()),
          'bloodType': _bloodTypeController.text.trim(),
          'emergencyContactName': _emergencyNameController.text.trim(),
          'emergencyContactPhone': _unformatPhoneNumber(_emergencyPhoneController.text), // Salvar sem formatação
          'observations': _observationsController.text.trim(),
          'profileImage': _profileImageBase64,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        };

        await _storage.saveUser(profile);

        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        
        setState(() {
          _isEditing = false;
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar perfil: $e'),
            backgroundColor: const Color(0xFFD32F2F),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveCloudMedsLocally() async {
    try {
      final status = await _syncService.getSyncStatus();
      if (!status['isLoggedIn'] || status['cloudUserId'] == null) return;

      print('🔄 Salvando medicamentos da nuvem para uso local...');
      
      final cloudMeds = await _syncService.loadFromCloud(status['cloudUserId']);
      
      if (cloudMeds.isNotEmpty) {
        print('📦 Salvando ${cloudMeds.length} medicamentos localmente');
        
        final localMeds = await _medicationService.getMedicationsList(_localUserId);
        for (var med in localMeds) {
          await _medicationService.deleteMedication(med.id);
        }
        
        for (var med in cloudMeds) {
          final localMed = MedicationModel(
            id: med.id,
            userId: _localUserId,
            name: med.name,
            hour: med.hour,
            minute: med.minute,
            frequency: med.frequency,
            notes: med.notes,
            createdAt: med.createdAt,
          );
          await _medicationService.addMedication(localMed);
        }
        
        print('✅ Medicamentos salvos localmente com sucesso!');
      }
    } catch (e) {
      print('❌ Erro ao salvar medicamentos localmente: $e');
      rethrow;
    }
  }

  Future<void> _confirmLogout() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Sair da Conta',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Tem certeza que deseja sair da sua conta?\n\n'
            'Seus medicamentos serão salvos no seu celular para você continuar usando mesmo sem internet.',
            style: TextStyle(fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'NÃO',
                style: TextStyle(fontSize: 18, color: Color(0xFF1976D2)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'SIM, SAIR',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _saveCloudMedsLocally();
      await _syncService.logoutFromCloud();
      await _authService.signOut();
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você saiu da sua conta com sucesso!\nSeus medicamentos foram salvos no celular.'),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 4),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MedicationListPage()),
        (route) => false,
      );
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao sair da conta: $e'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF1976D2),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: const Color(0xFFE3F2FD),
            backgroundImage: _profileImageBytes != null
                ? MemoryImage(_profileImageBytes!)
                : null,
            child: _profileImageBytes == null
                ? const Icon(
                    Icons.person,
                    size: 60,
                    color: Color(0xFF1976D2),
                  )
                : null,
          ),
        ),
        
        if (_isImageLoading)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black26,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ),
          ),
        
        if (_isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: _profileImageBytes == null
                    ? const Color(0xFF388E3C)
                    : const Color(0xFFF57C00),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: PopupMenuButton<String>(
                icon: Icon(
                  _profileImageBytes == null ? Icons.add_a_photo : Icons.edit,
                  color: Colors.white,
                  size: 20,
                ),
                offset: const Offset(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onSelected: (String value) {
                  if (value == 'camera') {
                    _pickImage(ImageSource.camera);
                  } else if (value == 'gallery') {
                    _pickImage(ImageSource.gallery);
                  } else if (value == 'remove') {
                    _confirmRemoveImage();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'camera',
                    child: Row(
                      children: [
                        Icon(Icons.camera_alt, color: Color(0xFF1976D2)),
                        SizedBox(width: 8),
                        Text('Tirar foto'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'gallery',
                    child: Row(
                      children: [
                        Icon(Icons.photo_library, color: Color(0xFF1976D2)),
                        SizedBox(width: 8),
                        Text('Escolher da galeria'),
                      ],
                    ),
                  ),
                  if (_profileImageBytes != null)
                    const PopupMenuItem<String>(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Color(0xFFD32F2F)),
                          SizedBox(width: 8),
                          Text('Remover foto'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        
        if (_isCloudUser)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
                border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
              ),
              child: const Icon(
                Icons.cloud_done,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
      ],
    );
  }

  // Helper para mostrar hint do formato de telefone
  Widget _buildPhoneHint() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 4),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            'Formato: +55 (47) 99999-9999',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: _toggleEdit,
            tooltip: _isEditing ? 'Cancelar' : 'Editar',
          ),
          if (_isEditing)
            IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
              onPressed: _isLoading ? null : _saveProfile,
              tooltip: 'Salvar',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Color(0xFF1976D2)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Carregando perfil...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF212121),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProfileImage(),
                    const SizedBox(height: 20),
                    
                    // Informações Pessoais
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informações Pessoais',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF212121),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Nome
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Nome completo',
                                prefixIcon: const Icon(Icons.person, color: Color(0xFF757575)),
                                hintText: _cloudUserData != null && _nameController.text.isEmpty 
                                    ? _cloudUserData!.name 
                                    : null,
                              ),
                              enabled: _isEditing,
                              validator: (value) {
                                if (_isEditing && (value == null || value.isEmpty)) {
                                  return 'Por favor, digite seu nome';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Email
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'E-mail',
                                prefixIcon: Icon(Icons.email, color: Color(0xFF757575)),
                              ),
                              enabled: _isEditing,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (_isEditing && value != null && value.isNotEmpty) {
                                  if (!value.contains('@') || !value.contains('.')) {
                                    return 'Digite um e-mail válido';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Telefone (com formatação)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _phoneController,
                                  decoration: const InputDecoration(
                                    labelText: 'Telefone',
                                    prefixIcon: Icon(Icons.phone, color: Color(0xFF757575)),
                                  ),
                                  enabled: _isEditing,
                                  keyboardType: TextInputType.phone,
                                ),
                                _buildPhoneHint(),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Idade
                            TextFormField(
                              controller: _ageController,
                              decoration: const InputDecoration(
                                labelText: 'Idade',
                                prefixIcon: Icon(Icons.cake, color: Color(0xFF757575)),
                              ),
                              enabled: _isEditing,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            
                            // Tipo Sanguíneo
                            DropdownButtonFormField<String>(
                              value: _bloodTypeController.text.isNotEmpty 
                                  ? _bloodTypeController.text 
                                  : null,
                              decoration: const InputDecoration(
                                labelText: 'Tipo Sanguíneo',
                                prefixIcon: Icon(Icons.bloodtype, color: Color(0xFF757575)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'A+', child: Text('A+')),
                                DropdownMenuItem(value: 'A-', child: Text('A-')),
                                DropdownMenuItem(value: 'B+', child: Text('B+')),
                                DropdownMenuItem(value: 'B-', child: Text('B-')),
                                DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                                DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                                DropdownMenuItem(value: 'O+', child: Text('O+')),
                                DropdownMenuItem(value: 'O-', child: Text('O-')),
                                DropdownMenuItem(value: 'Não sei', child: Text('Não sei')),
                              ],
                              onChanged: _isEditing ? (value) {
                                setState(() {
                                  _bloodTypeController.text = value ?? '';
                                });
                              } : null,
                              validator: (value) {
                                if (_isEditing && (value == null || value.isEmpty)) {
                                  return 'Por favor, selecione seu tipo sanguíneo';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Contato de Emergência
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Contato de Emergência',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF212121),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Nome do Contato
                            TextFormField(
                              controller: _emergencyNameController,
                              decoration: const InputDecoration(
                                labelText: 'Nome do contato',
                                prefixIcon: Icon(Icons.contact_emergency, color: Color(0xFF757575)),
                              ),
                              enabled: _isEditing,
                            ),
                            const SizedBox(height: 16),
                            
                            // Telefone do Contato (com formatação)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _emergencyPhoneController,
                                  decoration: const InputDecoration(
                                    labelText: 'Telefone do contato',
                                    prefixIcon: Icon(Icons.phone, color: Color(0xFF757575)),
                                  ),
                                  enabled: _isEditing,
                                  keyboardType: TextInputType.phone,
                                ),
                                _buildPhoneHint(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Observações
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Observações',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF212121),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _observationsController,
                              decoration: const InputDecoration(
                                labelText: 'Observações médicas ou alergias',
                                prefixIcon: Icon(Icons.note, color: Color(0xFF757575)),
                              ),
                              enabled: _isEditing,
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Botão de Sair da Conta
                    if (_isCloudUser) ...[
                      Center(
                        child: Container(
                          width: 280,
                          height: 48,
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          child: ElevatedButton(
                            onPressed: _confirmLogout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD32F2F),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.exit_to_app, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'SAIR DA CONTA',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.only(top: 4, bottom: 16),
                        child: Text(
                          'Ao sair, seus medicamentos continuam salvos no celular.\n'
                          'Quando você entrar novamente, eles serão sincronizados.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _phoneController.removeListener(_formatPhoneOnChange);
    _emergencyPhoneController.removeListener(_formatEmergencyPhoneOnChange);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _bloodTypeController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _observationsController.dispose();
    super.dispose();
  }
}