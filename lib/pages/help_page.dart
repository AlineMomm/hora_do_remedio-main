import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE4EC),
      appBar: AppBar(
        title: const Text(
          'Ajuda e Como Usar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 30),
            _buildIconsSection(),
            const SizedBox(height: 30),
            _buildFunctionsSection(),
            const SizedBox(height: 30),
            _buildTipsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.medical_services,
              size: 60,
              color: const Color(0xFFE91E63),
            ),
            const SizedBox(height: 15),
            const Text(
              'Bem-vindo ao Hora do Remédio!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC2185B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Este aplicativo foi feito especialmente para ajudar você a lembrar de tomar seus remédios nos horários certos. É muito simples de usar!',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconsSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📱 O que significa cada ícone:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC2185B),
              ),
            ),
            const SizedBox(height: 20),
            _buildIconItem(
              Icons.add,
              'Botão Adicionar',
              'Toque aqui para cadastrar um novo remédio. Aparece como um botão redondo com "+" na parte de baixo da tela.',
            ),
            _buildIconItem(
              Icons.edit,
              'Lápis (Editar)',
              'Toque neste ícone para modificar as informações de um remédio que já cadastrou.',
            ),
            _buildIconItem(
              Icons.delete,
              'Lixeira (Excluir)',
              'Toque aqui para remover um remédio da sua lista. O app vai perguntar se você tem certeza antes de excluir.',
            ),
            _buildIconItem(
              Icons.person,
              'Silhueta (Perfil)',
              'Toque aqui para ver e editar suas informações pessoais, como telefone, tipo sanguíneo e contato de emergência.',
            ),
            _buildIconItem(
              Icons.help_outline,
              'Ponto de Interrogação (Ajuda)',
              'Toque aqui sempre que tiver dúvidas sobre como usar o aplicativo. Esta tela vai aparecer!',
            ),
            _buildIconItem(
              Icons.exit_to_app,
              'Porta de Saída (Sair)',
              'Toque aqui para sair da sua conta e voltar para a tela inicial.',
            ),
            _buildIconItem(
              Icons.access_time,
              'Relógio (Horário)',
              'Mostra o horário em que você deve tomar cada remédio.',
            ),
            _buildIconItem(
              Icons.repeat,
              'Seta Circular (Frequência)',
              'Mostra de quanto em quanto tempo você deve tomar o remédio (todo dia, toda semana, etc.).',
            ),
            _buildIconItem(
              Icons.medical_services,
              'Cruz Médica (Remédio)',
              'Representa cada medicamento que você cadastrou.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF8BBD0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFE91E63),
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC2185B),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionsSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎯 Como usar as principais funções:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC2185B),
              ),
            ),
            const SizedBox(height: 20),
            _buildFunctionItem(
              'Cadastrar um Remédio',
              '1. Toque no botão "+" (mais) na parte de baixo da tela\n2. Digite o nome do remédio\n3. Escolha o horário tocando no relógio\n4. Selecione a frequência\n5. Toque em "CADASTRAR"',
            ),
            _buildFunctionItem(
              'Ver seus Remédios',
              'Na tela principal você vê todos os remédios que cadastrou, organizados por horário. Cada card mostra:\n• Nome do remédio\n• Horário para tomar\n• Frequência\n• Observações (se tiver)',
            ),
            _buildFunctionItem(
              'Receber Lembretes',
              'O app avisa você quando chegar a hora de tomar cada remédio. Um alerta vai aparecer na tela do celular com o nome do remédio.',
            ),
            _buildFunctionItem(
              'Editar suas Informações',
              '1. Toque no ícone de perfil (silhueta)\n2. Toque no lápis para editar\n3. Preencha suas informações\n4. Toque no ícone de salvar (disquete)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunctionItem(String title, String steps) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC2185B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            steps,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💡 Dicas Importantes:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC2185B),
              ),
            ),
            const SizedBox(height: 15),
            _buildTipItem('Sempre mantenha suas informações atualizadas no perfil'),
            _buildTipItem('Cadastre todos os remédios que toma regularmente'),
            _buildTipItem('Verifique se o horário do celular está correto'),
            _buildTipItem('Mantenha o volume do celular ligado para ouvir os alertas'),
            _buildTipItem('Se tiver dúvidas, volte sempre nesta tela de ajuda'),
            _buildTipItem('Peça ajuda a um familiar se precisar'),
            const SizedBox(height: 15),
            const Text(
              'Lembre-se: este aplicativo é seu amigo para cuidar da sua saúde!',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Color(0xFFE91E63),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF4CAF50),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}