import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/activity_service.dart';
import '../services/balance_service.dart';
import '../models/user_data.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});
  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  String? _activeMenu;

  final List<Map<String, dynamic>> _menus = [
    {
      'icon': Icons.account_balance_rounded,
      'title': 'Transfer Antar Bank',
      'desc': 'Transfer ke rekening bank lain',
      'color': AppColors.transfer,
    },
    {
      'icon': Icons.people_alt_rounded,
      'title': 'Transfer Sesama',
      'desc': 'Transfer ke sesama nasabah SmartBank',
      'color': AppColors.topup,
    },
    {
      'icon': Icons.schedule_rounded,
      'title': 'Transfer Terjadwal',
      'desc': 'Atur jadwal transfer otomatis',
      'color': AppColors.warning,
    },
    {
      'icon': Icons.history_rounded,
      'title': 'Riwayat Transfer',
      'desc': 'Lihat semua riwayat transfer',
      'color': AppColors.qris,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Column(
          children: [
            // Custom header
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: _activeMenu != null
                                ? () => setState(() => _activeMenu = null)
                                : () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white, size: 20),
                          ),
                          Text(
                            _activeMenu ?? 'Transfer',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      if (_activeMenu == null) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.account_balance_wallet_rounded,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Saldo Tersedia',
                                        style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.8),
                                            fontSize: 12)),
                                    Text(BalanceService.formattedBalance,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Body
            Expanded(
              child: _activeMenu == null
                  ? _buildMenuList()
                  : _activeMenu == 'Riwayat Transfer'
                      ? _buildRiwayat()
                      : _buildForm(_activeMenu!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuList() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ..._menus.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _activeMenu = m['title']),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: (m['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(m['icon'] as IconData,
                            color: m['color'] as Color, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m['title'],
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                )),
                            const SizedBox(height: 3),
                            Text(m['desc'],
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 16, color: AppColors.textHint),
                    ],
                  ),
                ),
              ),
            )),

        // Recent recipients
        const SizedBox(height: 8),
        const Text('Penerima Terakhir',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _recentRecipient('Budi S.', 'BCA'),
            _recentRecipient('Ani W.', 'Mandiri'),
            _recentRecipient('Citra R.', 'BNI'),
            _recentRecipient('Deni P.', 'BRI'),
          ],
        ),
      ],
    );
  }

  Widget _recentRecipient(String name, String bank) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              name[0],
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(name.split(' ')[0],
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        Text(bank,
            style:
                const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildForm(String menuTitle) {
    final _noRekController = TextEditingController();
    final _nominalController = TextEditingController();
    final _catatanController = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Nomor Rekening Tujuan'),
          const SizedBox(height: 8),
          TextField(
            controller: _noRekController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Masukkan nomor rekening',
                prefixIcon: Icons.credit_card_rounded),
          ),
          const SizedBox(height: 20),
          _fieldLabel('Nominal Transfer'),
          const SizedBox(height: 8),
          TextField(
            controller: _nominalController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Rp 0',
                prefixIcon: Icons.attach_money_rounded),
          ),
          const SizedBox(height: 8),
          // Quick amounts
          Wrap(
            spacing: 8,
            children: ['50.000', '100.000', '250.000', '500.000']
                .map((v) => GestureDetector(
                      onTap: () => _nominalController.text = v,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Rp $v',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          _fieldLabel('Catatan (Opsional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _catatanController,
            decoration: _inputDecoration('Contoh: Pembayaran utang',
                prefixIcon: Icons.notes_rounded),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                final noRek = _noRekController.text.trim();
                final rawNominal = _nominalController.text.replaceAll('.', '').trim();
                final catatan = _catatanController.text.trim();

                if (noRek.isEmpty || rawNominal.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Nomor rekening dan nominal wajib diisi'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.all(16),
                  ));
                  return;
                }

                final amount = BalanceService.parseNominal(rawNominal);

                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Nominal tidak valid'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.all(16),
                  ));
                  return;
                }

                if (!BalanceService.debit(amount)) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'Saldo tidak mencukupi. Saldo Anda: ${BalanceService.formattedBalance}'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                  ));
                  return;
                }

                final fmt = 'Rp ' + rawNominal.replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

                ActivityService.addTransaction(TransactionRecord(
                  type: 'transfer',
                  title: 'Transfer via $menuTitle',
                  nominal: fmt,
                  target: noRek,
                  catatan: catatan.isNotEmpty ? catatan : null,
                  time: DateTime.now(),
                ));

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Transfer via $menuTitle berhasil dikirim!'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ));
                setState(() => _activeMenu = null);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Konfirmasi Transfer',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayat() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final items = [
          {'title': 'Transfer ke Budi Santoso', 'amount': '-Rp 500.000', 'date': 'Kemarin 14:30', 'bank': 'BCA'},
          {'title': 'Transfer ke Ani Wijaya', 'amount': '-Rp 200.000', 'date': '2 hari lalu', 'bank': 'Mandiri'},
          {'title': 'Transfer Terjadwal', 'amount': '-Rp 1.000.000', 'date': '5 hari lalu', 'bank': 'BNI'},
        ];
        final item = items[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.transfer.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.send_rounded,
                    color: AppColors.transfer, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title']!,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Text('${item['bank']} • ${item['date']}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Text(item['amount']!,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary)),
            ],
          ),
        );
      },
    );
  }

  Widget _fieldLabel(String label) => Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      );

  InputDecoration _inputDecoration(String hint, {required IconData prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint),
      prefixIcon: Icon(prefixIcon, color: AppColors.textHint, size: 20),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
