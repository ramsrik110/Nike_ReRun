import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> bulkUploadEverything() async {

    // ═══════════════════════════════════════════
    // SHOES COLLECTION — 9 DOCUMENTS
    // ═══════════════════════════════════════════
    final List<Map<String, dynamic>> shoes = [
      {
        'SUID': 'NR-2024-AF1-0001',
        'SNM': 'Nike Air Force 1 \'07 Men\'s Shoes',
        'SNM-HDL': 'LEGENDARY STYLE, REFINED.',
        'SNM-DSC': 'The b-ball OG, now closing the loop.',
        'SNM-IMG': 'https://static.nike.com/a/images/t_web_pdp_535_v2/f_auto,u_9ddf04c7-2a9a-4d76-add1-d15af8f0263d,c_scale,fl_relative,w_1.0,h_1.0,fl_layer_apply/b7d9211c-26e7-431a-ac24-b0540fb3c00f/AIR+FORCE+1+%2707.png',
        'MCP-FLK': 0,
        'MCP-RBR': 30,
        'MCP-FOM': 20,
        'MCP-LTH': 50,
        'MFG-CTR': 'China',
        'MFG-NRG': '100% Renewable Energy',
        'ECO-CO2': 3.2,
        'LCS-RPR': [],
        'LCS-STS': 'IN THE GAME.',
        'RTE-DCN': 'PENDING.',
        'CUID-LNK': '',
        'TXN-DTP': '01/01/2024',
        'RWD-AMT': 120,
      },
      {
        'SUID': 'NR-2024-PEG-0003',
        'SNM': 'Nike Pegasus 42 Men\'s Road Running Shoes',
        'SNM-HDL': 'YOUR FASTEST DAYS AHEAD.',
        'SNM-DSC': 'ReactX foam meets a second chance.',
        'SNM-IMG': 'https://static.nike.com/a/images/t_web_pdp_535_v2/f_auto,u_9ddf04c7-2a9a-4d76-add1-d15af8f0263d,c_scale,fl_relative,w_1.0,h_1.0,fl_layer_apply/935d489c-7819-4a65-ab22-7c2c68b45a7f/AIR+ZOOM+PEGASUS+42.png',
        'MCP-FLK': 0,
        'MCP-RBR': 28,
        'MCP-FOM': 42,
        'MCP-LTH': 30,
        'MFG-CTR': 'Vietnam',
        'MFG-NRG': '100% Renewable Energy',
        'ECO-CO2': 4.1,
        'LCS-RPR': [],
        'LCS-STS': 'IN THE GAME.',
        'RTE-DCN': 'PENDING.',
        'CUID-LNK': '',
        'TXN-DTP': '01/01/2024',
        'RWD-AMT': 120,
      },
      {
        'SUID': 'NR-2024-STP-0005',
        'SNM': 'Nike Structure Plus Road Running Shoes',
        'SNM-HDL': 'BUILT FOR THE LONG RUN.',
        'SNM-DSC': 'Built for roads, ready for rebirth.',
        'SNM-IMG': 'https://static.nike.com/a/images/t_web_pdp_535_v2/f_auto,u_9ddf04c7-2a9a-4d76-add1-d15af8f0263d,c_scale,fl_relative,w_1.0,h_1.0,fl_layer_apply/a5365e84-ddd5-4d69-bcac-6deb69b2cb81/NIKE+STRUCTURE+PLUS.png',
        'MCP-FLK': 0,
        'MCP-RBR': 30,
        'MCP-FOM': 45,
        'MCP-LTH': 25,
        'MFG-CTR': 'Vietnam',
        'MFG-NRG': '100% Renewable Energy',
        'ECO-CO2': 4.1,
        'LCS-RPR': [],
        'LCS-STS': 'IN THE GAME.',
        'RTE-DCN': 'PENDING.',
        'CUID-LNK': '',
        'TXN-DTP': '01/01/2024',
        'RWD-AMT': 120,
      },
      {
        'SUID': 'NR-2024-AM90-0006',
        'SNM': 'Nike Air Max 90 LTR Men\'s Shoes',
        'SNM-HDL': 'CLASSIC NEVER GETS OLD.',
        'SNM-DSC': 'Crisp leather. Clean conscience.',
        'SNM-IMG': 'https://static.nike.com/a/images/t_web_pdp_535_v2/f_auto,u_9ddf04c7-2a9a-4d76-add1-d15af8f0263d,c_scale,fl_relative,w_1.0,h_1.0,fl_layer_apply/7b6ccd0a-2e86-4fac-8f13-a0d11c5f90df/AIR+MAX+90+LTR.png',
        'MCP-FLK': 0,
        'MCP-RBR': 32,
        'MCP-FOM': 24,
        'MCP-LTH': 44,
        'MFG-CTR': 'Vietnam',
        'MFG-NRG': '100% Renewable Energy',
        'ECO-CO2': 3.2,
        'LCS-RPR': [],
        'LCS-STS': 'IN THE GAME.',
        'RTE-DCN': 'PENDING.',
        'CUID-LNK': '',
        'TXN-DTP': '01/01/2024',
        'RWD-AMT': 120,
      },
      {
        'SUID': 'NR-2024-PEG-0007',
        'SNM': 'Nike Pegasus 42 By You Custom Men\'s Road-Running Shoes',
        'SNM-HDL': 'MADE BY YOU. WORN BY YOU.',
        'SNM-DSC': 'Custom made, circularly remade.',
        'SNM-IMG': 'https://static.nike.com/a/images/t_web_pdp_535_v2/f_auto,u_9ddf04c7-2a9a-4d76-add1-d15af8f0263d,c_scale,fl_relative,w_1.0,h_1.0,fl_layer_apply/a7fd70c5-c71b-4275-91fa-9aab37d49f0b/AIR+ZOOM+PEGASUS+42+NBY.png',
        'MCP-FLK': 0,
        'MCP-RBR': 28,
        'MCP-FOM': 42,
        'MCP-LTH': 30,
        'MFG-CTR': 'Vietnam',
        'MFG-NRG': '100% Renewable Energy',
        'ECO-CO2': 4.1,
        'LCS-RPR': [],
        'LCS-STS': 'IN THE GAME.',
        'RTE-DCN': 'PENDING.',
        'CUID-LNK': '',
        'TXN-DTP': '01/01/2024',
        'RWD-AMT': 150,
      },
      {
        'SUID': 'NR-2024-REV-0008',
        'SNM': 'Nike Revolution 8 Women\'s Road Running Shoes',
        'SNM-HDL': 'EVERY RUN COUNTS.',
        'SNM-DSC': 'Every kilometre, every material, recovered.',
        'SNM-IMG': 'https://static.nike.com/a/images/t_web_pdp_535_v2/f_auto,u_9ddf04c7-2a9a-4d76-add1-d15af8f0263d,c_scale,fl_relative,w_1.0,h_1.0,fl_layer_apply/72787153-b9c7-47ea-9fc1-2b8c753fd7c0/NIKE+REVOLUTION+8.png',
        'MCP-FLK': 0,
        'MCP-RBR': 26,
        'MCP-FOM': 44,
        'MCP-LTH': 30,
        'MFG-CTR': 'Indonesia',
        'MFG-NRG': '100% Renewable Energy',
        'ECO-CO2': 4.1,
        'LCS-RPR': [],
        'LCS-STS': 'IN THE GAME.',
        'RTE-DCN': 'PENDING.',
        'CUID-LNK': '',
        'TXN-DTP': '01/01/2024',
        'RWD-AMT': 120,
      },
      {
        'SUID': 'NR-2024-AM270-0009',
        'SNM': 'Nike Air Max 270 Men\'s Shoes',
        'SNM-HDL': 'MAX AIR. MAX ATTITUDE.',
        'SNM-DSC': 'Max Air cushioning, minimum waste.',
        'SNM-IMG': 'https://static.nike.com/a/images/t_web_pdp_535_v2/f_auto,u_9ddf04c7-2a9a-4d76-add1-d15af8f0263d,c_scale,fl_relative,w_1.0,h_1.0,fl_layer_apply/awjogtdnqxniqqk0wpgf/AIR+MAX+270.png',
        'MCP-FLK': 0,
        'MCP-RBR': 30,
        'MCP-FOM': 26,
        'MCP-LTH': 44,
        'MFG-CTR': 'Vietnam',
        'MFG-NRG': '100% Renewable Energy',
        'ECO-CO2': 3.2,
        'LCS-RPR': [],
        'LCS-STS': 'IN THE GAME.',
        'RTE-DCN': 'PENDING.',
        'CUID-LNK': '',
        'TXN-DTP': '01/01/2024',
        'RWD-AMT': 120,
      },
      {
        'SUID': 'NR-2024-MTC-0010',
        'SNM': 'Nike Metcon 10 Women\'s Workout Shoes',
        'SNM-HDL': 'TRAIN HARDER. LIFT SMARTER.',
        'SNM-DSC': 'Trained hard. Now it trains again.',
        'SNM-IMG': 'https://static.nike.com/a/images/t_web_pdp_535_v2/f_auto,u_9ddf04c7-2a9a-4d76-add1-d15af8f0263d,c_scale,fl_relative,w_1.0,h_1.0,fl_layer_apply/5709c27f-742f-4236-93c5-fd398cde51f9/M+NIKE+METCON+10.png',
        'MCP-FLK': 0,
        'MCP-RBR': 34,
        'MCP-FOM': 38,
        'MCP-LTH': 28,
        'MFG-CTR': 'Vietnam',
        'MFG-NRG': '100% Renewable Energy',
        'ECO-CO2': 3.8,
        'LCS-RPR': [],
        'LCS-STS': 'IN THE GAME.',
        'RTE-DCN': 'PENDING.',
        'CUID-LNK': '',
        'TXN-DTP': '01/01/2024',
        'RWD-AMT': 120,
      },
      {
        'SUID': 'NR-2024-FRN-0011',
        'SNM': 'Nike Free RN By You Custom Men\'s Road Running Shoes',
        'SNM-HDL': 'YOUR RULES. YOUR RUN.',
        'SNM-DSC': 'You ran in it. Now it runs again.',
        'SNM-IMG': 'https://static.nike.com/a/images/t_web_pdp_535_v2/f_auto/7441a74f-7848-4c27-a74f-433e57eaceb2/NIKE+FREE+RN+FK+NN+NBY.png',
        'MCP-FLK': 45,
        'MCP-RBR': 25,
        'MCP-FOM': 30,
        'MCP-LTH': 0,
        'MFG-CTR': 'Vietnam',
        'MFG-NRG': '100% Renewable Energy',
        'ECO-CO2': 4.1,
        'LCS-RPR': [],
        'LCS-STS': 'IN THE GAME.',
        'RTE-DCN': 'PENDING.',
        'CUID-LNK': '',
        'TXN-DTP': '01/01/2024',
        'RWD-AMT': 150,
      },
    ];

    // ═══════════════════════════════════════════
    // CUSTOMERS COLLECTION — 1 DOCUMENT
    // ═══════════════════════════════════════════
    final Map<String, dynamic> customer = {
      'CUID': 'CUST-001',
      'CST-NM': 'Ram Sri Karan Mylavarapu',
      'CST-EML': 'mramsrikaran110@gmail.com',
      'RWD-NCB': 120,
      'SUID-LNK': ['NR-2024-AM90-0006'],
      'LCS-RTN': [],
      'DGT-WLT': true,
      'ACC-TYP': 'MEMBER',
    };

    // ═══════════════════════════════════════════
    // HUBS COLLECTION — 1 DOCUMENT
    // ═══════════════════════════════════════════
    final Map<String, dynamic> hub = {
      'HUID': 'HUB-001',
      'HUB-NM': 'Berlin Hub',
      'HUB-CTY': 'Berlin',
      'HUB-CTR': 'Germany',
      'HUB-LNS': 3,
      'HUB-TSP': 0,
      'HUB-DSC': 'Berlin Circular Processing Hub',
      'RTE-LOG': [],
      'HUB-STS': 'IN OPERATION.',
    };

    // ═══════════════════════════════════════════
    // DASHBOARD COLLECTION — 1 DOCUMENT
    // ═══════════════════════════════════════════
    final Map<String, dynamic> dashboard = {
      'ECO-CO2T': 1284,
      'OPS-TSP': 48392,
      'ECO-RMP': 67,
      'OPS-AHC': 23,
      'RPT-MTD': [1050, 1100, 1150, 1200, 1240, 1284],
      'RPT-LUD': '21/05/2026',
      'RPT-RGN': 'GLOBAL',
    };

    try {
      final WriteBatch batch = _firestore.batch();

      // Upload all 9 shoes
      for (final shoe in shoes) {
        final docRef = _firestore
            .collection('Shoes')
            .doc(shoe['SUID'] as String);
        batch.set(docRef, shoe);
      }

      // Upload customer
      final customerRef = _firestore
          .collection('customers')
          .doc('CUST-001');
      batch.set(customerRef, customer);

      // Upload hub
      final hubRef = _firestore
          .collection('hubs')
          .doc('HUB-001');
      batch.set(hubRef, hub);

      // Upload dashboard
      final dashboardRef = _firestore
          .collection('dashboard')
          .doc('DASHBOARD-GLOBAL');
      batch.set(dashboardRef, dashboard);

      await batch.commit();
      print('🚀 ALL COLLECTIONS SUCCESSFULLY LOADED!');
      print('✅ 9 Shoes uploaded');
      print('✅ 1 Customer uploaded');
      print('✅ 1 Hub uploaded');
      print('✅ 1 Dashboard uploaded');

    } catch (e) {
      print('❌ Error uploading data: $e');
    }
  }
}