import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/du_campus_service.dart';

// ── Graph data models and Complete Delhi Metro Network Graph ─────────────────
class StationConnection {
  final String station;
  final String line;
  StationConnection(this.station, this.line);
}

class MetroPath {
  final List<String> stations;
  final List<String> lines;
  final int interchanges;
  
  MetroPath({
    required this.stations,
    required this.lines,
    required this.interchanges,
  });
}

// Complete Delhi Metro station list of all 10 lines
final Map<String, List<String>> metroLines = {
  'Red': [
    'Shaheed Sthal', 'Hindon River', 'Arthala', 'Mohan Nagar', 'Shyam Park', 
    'Major Mohit Sharma Rajendra Nagar', 'Raj Bagh', 'Shahid Nagar', 'Dilshad Garden', 
    'Jhilmil', 'Mansarovar Park', 'Shahdara', 'Welcome', 'Seelampur', 'Shastri Park', 
    'Kashmere Gate', 'Tis Hazari', 'Pul Bangash', 'Pratap Nagar', 'Shastri Nagar', 
    'Inderlok', 'Kanhaiya Nagar', 'Keshav Puram', 'Netaji Subhash Place', 'Shakurpur', 
    'Kohat Enclave', 'Pitam Pura', 'Rohini East', 'Rohini West', 'Rithala'
  ],
  'Yellow': [
    'Samaypur Badli', 'Rohini Sector 18, 19', 'Haiderpur Badli Mor', 'Jahangirpuri', 
    'Adarsh Nagar', 'Azadpur', 'Model Town', 'GTB Nagar', 'Vishwa Vidyalaya', 
    'Civil Lines', 'Kashmere Gate', 'Chandni Chowk', 'Chawri Bazar', 'New Delhi', 
    'Rajiv Chowk', 'Patel Chowk', 'Central Secretariat', 'Udyog Bhawan', 'Lok Kalyan Marg', 
    'Jor Bagh', 'Dilli Haat INA', 'AIIMS', 'Green Park', 'Hauz Khas', 'Malviya Nagar', 
    'Saket', 'Qutab Minar', 'Chhattarpur', 'Sultanpur', 'Ghitorni', 'Arjan Garh', 
    'Guru Dronacharya', 'Sikanderpur', 'MG Road', 'IFFCO Chowk', 'Millennium City Centre Gurugram'
  ],
  'Blue': [
    'Dwarka Sector 21', 'Dwarka Sector 8', 'Dwarka Sector 9', 'Dwarka Sector 10', 
    'Dwarka Sector 11', 'Dwarka Sector 12', 'Dwarka Sector 13', 'Dwarka Sector 14', 
    'Dwarka', 'Dwarka Mor', 'Nawada', 'Uttam Nagar West', 'Uttam Nagar East', 
    'Janakpuri West', 'Janakpuri East', 'Tilak Nagar', 'Subhash Nagar', 'Tagore Garden', 
    'Rajouri Garden', 'Ramesh Nagar', 'Moti Nagar', 'Kirti Nagar', 'Shadipur', 
    'Patel Nagar', 'Rajendra Place', 'Karol Bagh', 'Jhandewalan', 'Ramakrishna Ashram Marg', 
    'Rajiv Chowk', 'Barakhamba Road', 'Mandi House', 'Supreme Court', 'Indraprastha', 
    'Yamuna Bank', 'Akshardham', 'Mayur Vihar Phase-1', 'Mayur Vihar Extension', 
    'New Ashok Nagar', 'Noida Sector 15', 'Noida Sector 16', 'Noida Sector 18', 
    'Botanical Garden', 'Noida Golf Course', 'Noida City Centre', 'Noida Sector 34', 
    'Noida Sector 52', 'Noida Sector 61', 'Noida Sector 59', 'Noida Sector 62', 
    'Noida Electronic City'
  ],
  'Blue Branch': [
    'Yamuna Bank', 'Laxmi Nagar', 'Nirman Vihar', 'Preet Vihar', 'Karkarduma', 
    'Anand Vihar ISBT', 'Kaushambi', 'Vaishali'
  ],
  'Green': [
    'Kirti Nagar', 'Ashok Park Main', 'East Punjabi Bagh', 'Punjabi Bagh', 'Shivaji Park', 
    'Madipur', 'Paschim Vihar East', 'Paschim Vihar West', 'Peeragarhi', 'Udyog Nagar', 
    'Surajmal Stadium', 'Nangloi', 'Nangloi Railway Station', 'Rajdhani Park', 'Mundka', 
    'Mundka Industrial Area', 'Ghevra Metro Station', 'Tikri Kalan', 'Tikri Border', 
    'Pandit Shree Ram Sharma', 'Bahadurgarh City', 'Brigadier Hoshiar Singh'
  ],
  'Violet': [
    'Kashmere Gate', 'Lal Quila', 'Jama Masjid', 'Delhi Gate', 'ITO', 'Mandi House', 
    'Central Secretariat', 'Khan Market', 'Jawaharlal Nehru Stadium', 'Jangpura', 
    'Lajpat Nagar', 'Moolchand', 'Kailash Colony', 'Nehru Place', 'Kalkaji Mandir', 
    'Govindpuri', 'Okhla', 'Jasola Apollo', 'Sarita Vihar', 'Mohan Estate', 
    'Badarpur Border', 'Sarai', 'Sector 28 Faridabad', 'Badkal Mor', 'Old Faridabad', 
    'Neelam Chowk Ajronda', 'Bata Chowk', 'Escorts Mujesar', 'Sant Surdas', 'Raja Nahar Singh'
  ],
  'Pink': [
    'Majlis Park', 'Azadpur', 'Shalimar Bagh', 'Netaji Subhash Place', 'Shakurpur', 
    'Punjabi Bagh West', 'Rajouri Garden', 'Mayapuri', 'Naraina Vihar', 'Delhi Cantt', 
    'Durgabai Deshmukh South Campus', 'Sir M. Vishweshwariah Moti Bagh', 'Bhikaji Cama Place', 
    'Sarojini Nagar', 'Dilli Haat INA', 'South Extension', 'Lajpat Nagar', 'Hazrat Nizamuddin', 
    'Mayur Vihar Pocket-1', 'Mayur Vihar Phase-1', 'Trilokpuri Sanjay Lake', 
    'East Vinod Nagar - Mayur Vihar-II', 'Mandawali - West Vinod Nagar', 'IP Extension', 
    'Anand Vihar ISBT', 'Karkarduma', 'Karkarduma Court', 'Krishna Nagar', 'East Azad Nagar', 
    'Welcome', 'Jaffrabad', 'Maujpur - Babarpur', 'Gokulpuri', 'Johri Enclave', 'Shiv Vihar'
  ],
  'Magenta': [
    'Janakpuri West', 'Dabri Mor - Janakpuri South', 'Dashrathpuri', 'Palam', 
    'Sadar Bazar Cantonment', 'Terminal 1-IGI Airport', 'Shankar Vihar', 'Vasant Vihar', 
    'Munirka', 'RK Puram', 'IIT Delhi', 'Hauz Khas', 'Panchsheel Park', 'Chirag Delhi', 
    'Greater Kailash', 'Nehru Enclave', 'Kalkaji Mandir', 'Okhla NSIC', 'Sukhdev Vihar', 
    'Jamia Millia Islamia', 'Okhla Vihar', 'Jasola Vihar Shaheen Bagh', 'Kalindi Kunj', 
    'Okhla Bird Sanctuary', 'Botanical Garden'
  ],
  'Airport Express': [
    'New Delhi', 'Shivaji Stadium', 'Dhaula Kuan', 'Delhi Aerocity', 'IGI Airport', 
    'Dwarka Sector 21', 'Yashobhoomi Dwarka Sector 25'
  ],
  'Grey': [
    'Dwarka', 'Nangli', 'Najafgarh', 'Dhansa Bus Stand'
  ]
};

final Map<String, List<StationConnection>> metroGraph = {};

void buildMetroGraph() {
  if (metroGraph.isNotEmpty) return;
  metroLines.forEach((lineName, stations) {
    for (int i = 0; i < stations.length; i++) {
      final station = stations[i];
      metroGraph.putIfAbsent(station, () => []);

      if (i > 0) {
        final prevStation = stations[i - 1];
        final exists = metroGraph[station]!.any((c) => c.station == prevStation && c.line == lineName);
        if (!exists) {
          metroGraph[station]!.add(StationConnection(prevStation, lineName));
        }
      }
      if (i < stations.length - 1) {
        final nextStation = stations[i + 1];
        final exists = metroGraph[station]!.any((c) => c.station == nextStation && c.line == lineName);
        if (!exists) {
          metroGraph[station]!.add(StationConnection(nextStation, lineName));
        }
      }
    }
  });
}

MetroPath? findShortestMetroPath(String start, String end) {
  buildMetroGraph();
  if (!metroGraph.containsKey(start) || !metroGraph.containsKey(end)) return null;
  if (start == end) {
    return MetroPath(stations: [start], lines: [], interchanges: 0);
  }

  final List<List<StationConnection>> queue = [
    [StationConnection(start, '')]
  ];
  final Set<String> visited = {start};

  while (queue.isNotEmpty) {
    final path = queue.removeAt(0);
    final lastNode = path.last.station;

    if (lastNode == end) {
      final stations = path.map((c) => c.station).toList();
      final lines = path.skip(1).map((c) => c.line).toList();
      
      int interchanges = 0;
      for (int i = 1; i < lines.length; i++) {
        if (lines[i] != lines[i - 1]) interchanges++;
      }

      return MetroPath(
        stations: stations,
        lines: lines,
        interchanges: interchanges,
      );
    }

    final neighbors = metroGraph[lastNode] ?? [];
    for (final neighbor in neighbors) {
      if (!visited.contains(neighbor.station)) {
        visited.add(neighbor.station);
        final newPath = List<StationConnection>.from(path)..add(neighbor);
        queue.add(newPath);
      }
    }
  }
  return null;
}

class CampusHubScreen extends StatefulWidget {
  const CampusHubScreen({super.key});

  @override
  State<CampusHubScreen> createState() => _CampusHubScreenState();
}

class _CampusHubScreenState extends State<CampusHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCampusFilter = 'All';

  // Budget Calculator variables
  int _dailyTrips = 2;
  double _customRickshawFare = 10.0;

  // Metro routing variables
  String _startStation = 'Vishwa Vidyalaya';
  String _endStation = 'Durgabai Deshmukh South Campus';
  MetroPath? _calculatedPath;
  bool _showAllIntermediateStations = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _calculateRoute();
  }

  void _calculateRoute() {
    setState(() {
      _calculatedPath = findShortestMetroPath(_startStation, _endStation);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final campusService = Provider.of<DuCampusService>(context);

    final filteredGuides = campusService.guides.where((g) {
      final matchesSearch = g.collegeName.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesCampus = _selectedCampusFilter == 'All' || g.campusType == _selectedCampusFilter.toLowerCase();
      return matchesSearch && matchesCampus;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text(
          'DU Campus & Transit Hub',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Metro & Transit'),
            Tab(text: 'PG & Hostels'),
            Tab(text: 'Campus Directory'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTransitTab(theme, isDark, filteredGuides),
          _buildPgTab(theme, isDark),
          _buildDirectoryTab(theme, isDark, campusService, filteredGuides),
        ],
      ),
    );
  }

  Widget _buildTransitTab(ThemeData theme, bool isDark, List<CampusGuideItem> guides) {
    final double monthlyRickshawCost = _dailyTrips * _customRickshawFare * 25;
    
    // Dynamically compile sorted list of all stations from the graph
    buildMetroGraph();
    final stationsList = metroGraph.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: () => Provider.of<DuCampusService>(context, listen: false).fetchGuides(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Intro
            Text(
              'Delhi Metro Transit Guide',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Search any station of Delhi Metro, solve optimal paths, interchanges & travel fares.',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // ── Metro Route Finder Widget (FREE & COMPREHENSIVE) ──────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.train, color: Colors.blueAccent, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Universal Metro Route Solver 🚇',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Covers all 250+ stations across all 10 network lines.',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  // Entry/Exit Dropdowns
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Entry Station',
                              style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF161C24) : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _startStation,
                                  isExpanded: true,
                                  items: stationsList.map((s) {
                                    return DropdownMenuItem<String>(
                                      value: s,
                                      child: Text(s, style: GoogleFonts.inter(fontSize: 12), overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _startStation = val);
                                      _calculateRoute();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Exit Station',
                              style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF161C24) : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _endStation,
                                  isExpanded: true,
                                  items: stationsList.map((s) {
                                    return DropdownMenuItem<String>(
                                      value: s,
                                      child: Text(s, style: GoogleFonts.inter(fontSize: 12), overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _endStation = val);
                                      _calculateRoute();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_calculatedPath != null) ...[
                    const Divider(height: 24),
                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatChip(
                          icon: LucideIcons.clock,
                          label: '${_calculatedPath!.stations.length * 2 + _calculatedPath!.interchanges * 4} Mins',
                          color: Colors.blue,
                        ),
                        _buildStatChip(
                          icon: LucideIcons.mapPin,
                          label: '${_calculatedPath!.stations.length - 1} Stops',
                          color: Colors.purple,
                        ),
                        _buildStatChip(
                          icon: LucideIcons.coins,
                          label: _getFareEstimate(_calculatedPath!.stations.length),
                          color: Colors.green,
                        ),
                        _buildStatChip(
                          icon: LucideIcons.refreshCw,
                          label: '${_calculatedPath!.interchanges} Changes',
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Detailed Collapsible Stepper Route
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Detailed Journey Route:',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() => _showAllIntermediateStations = !_showAllIntermediateStations);
                          },
                          icon: Icon(
                            _showAllIntermediateStations ? LucideIcons.eyeOff : LucideIcons.eye,
                            size: 14,
                          ),
                          label: Text(
                            _showAllIntermediateStations ? 'Collapse Stations' : 'Show All Stops',
                            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF161C24) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildRouteStepperList(theme, isDark),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Rickshaw Budget Estimator Widget
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.calculator, color: Color(0xFF6366F1), size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'E-Rickshaw Cost Estimator',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Estimate your monthly shared rickshaw travel budget inside the university complexes:',
                    style: GoogleFonts.inter(fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rickshaw One-way Fare',
                              style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            DropdownButton<double>(
                              value: _customRickshawFare,
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: [10.0, 15.0, 20.0, 25.0].map((f) {
                                return DropdownMenuItem<double>(
                                  value: f,
                                  child: Text('₹${f.toInt()} per trip'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _customRickshawFare = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trips Per Day',
                              style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            DropdownButton<int>(
                              value: _dailyTrips,
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: [1, 2, 3, 4].map((t) {
                                return DropdownMenuItem<int>(
                                  value: t,
                                  child: Text('$t trips/day'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _dailyTrips = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Monthly Estimated Budget:',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        '₹${monthlyRickshawCost.toInt()} / month',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // College Cards Loop
            Text(
              'Transit & Metro Indexes',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: guides.length,
              itemBuilder: (context, index) {
                final g = guides[index];
                final lineCol = _getLineColor(g.metroLine);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              g.collegeName,
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14.5),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: lineCol.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: lineCol.withOpacity(0.3)),
                            ),
                            child: Text(
                              '${g.metroLine} Line',
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: lineCol,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.train, color: Colors.blueGrey, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                g.nearestMetro,
                                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(LucideIcons.navigation, color: Colors.indigo, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${g.walkingDistanceMins} mins walk',
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(LucideIcons.zap, color: Colors.orange, size: 14),
                          const SizedBox(width: 8),
                          Text(
                            'Shared Rickshaw: ₹${g.eRickshawFare} one-way',
                            style: GoogleFonts.inter(fontSize: 11.5, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to construct smart, detailed, leg-by-leg collapsible timeline items
  List<Widget> _buildRouteStepperList(ThemeData theme, bool isDark) {
    final path = _calculatedPath;
    if (path == null) return [];

    final List<Widget> list = [];
    final total = path.stations.length;

    for (int i = 0; i < total; i++) {
      final currentStation = path.stations[i];
      final bool isStart = i == 0;
      final bool isEnd = i == total - 1;
      
      String line = '';
      if (i < path.lines.length) {
        line = path.lines[i];
      } else if (i > 0) {
        line = path.lines[i - 1];
      }

      final bool isJunction = i > 0 && i < total - 1 && path.lines[i - 1] != path.lines[i];

      // Draw Station Row
      list.add(
        Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: _getLineColor(line),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                currentStation,
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: isStart || isEnd || isJunction ? FontWeight.bold : FontWeight.w500,
                  color: isStart || isEnd || isJunction ? theme.textTheme.displayLarge?.color : Colors.grey.shade600,
                ),
              ),
            ),
            if (isStart) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'START',
                  style: GoogleFonts.outfit(fontSize: 8, color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
            ],
            if (isEnd) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'DESTINATION',
                  style: GoogleFonts.outfit(fontSize: 8, color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      );

      // Draw intermediate connection line
      if (i < total - 1) {
        final nextLine = path.lines[i];
        
        // Check if next is a junction or final. If intermediate station show/collapsible logic
        final bool showConnectorDetail = _showAllIntermediateStations || isStart || isJunction;

        if (showConnectorDetail) {
          list.add(
            Row(
              children: [
                Container(
                  width: 2,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  color: _getLineColor(nextLine),
                ),
                const SizedBox(width: 18),
                if (isJunction) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.refreshCw, size: 10, color: Colors.amber),
                        const SizedBox(width: 6),
                        Text(
                          'Change to $nextLine Line',
                          style: GoogleFonts.outfit(
                            fontSize: 9, 
                            color: Colors.amber.shade900, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    'Ride $nextLine Line',
                    style: GoogleFonts.inter(fontSize: 9.5, color: Colors.grey.shade400),
                  ),
                ],
              ],
            ),
          );
        } else {
          // Collapsed state: just draw a simple connector dot line
          // Find how many collapsed intermediate stations are in this chunk
          int intermediateCount = 0;
          int j = i;
          while (j < total - 1 && path.lines[j] == nextLine) {
            intermediateCount++;
            j++;
          }
          
          if (intermediateCount > 1) {
            list.add(
              Row(
                children: [
                  Column(
                    children: List.generate(3, (index) => Container(
                      width: 2,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                      color: _getLineColor(nextLine),
                    )),
                  ),
                  const SizedBox(width: 18),
                  GestureDetector(
                    onTap: () {
                      setState(() => _showAllIntermediateStations = true);
                    },
                    child: Text(
                      '↓ $intermediateCount intermediate stops (Tap to view)',
                      style: GoogleFonts.inter(
                        fontSize: 10.5, 
                        color: Colors.blueAccent, 
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            );
            // Skip the intermediate elements in our loop to output them collapsed!
            i += intermediateCount - 1;
          } else {
            // Draw regular short line
            list.add(
              Row(
                children: [
                  Container(
                    width: 2,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    color: _getLineColor(nextLine),
                  ),
                  const SizedBox(width: 18),
                  Text(
                    'Ride $nextLine Line',
                    style: GoogleFonts.inter(fontSize: 9.5, color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }
        }
      }
    }

    return list;
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getFareEstimate(int stationCount) {
    if (stationCount <= 2) return '₹10';
    if (stationCount <= 5) return '₹20';
    if (stationCount <= 12) return '₹30';
    if (stationCount <= 21) return '₹40';
    return '₹50';
  }

  // 🏠 Tab 2: PG & Accommodations finder guide
  Widget _buildPgTab(ThemeData theme, bool isDark) {
    final List<Map<String, dynamic>> hubs = [
      {
        'area': 'Kamla Nagar / Vijay Nagar',
        'campus': 'North Campus Hub',
        'price': '₹10,000 - ₹16,000',
        'rating': 4.8,
        'tag': 'Premium student hub',
        'accent': const Color(0xFF6366F1),
      },
      {
        'area': 'Satya Niketan',
        'campus': 'South Campus Hub',
        'price': '₹9,000 - ₹14,000',
        'rating': 4.6,
        'tag': 'Extremely popular, great food lanes',
        'accent': const Color(0xFF10B981),
      },
      {
        'area': 'Hudson Lane / GTB Nagar',
        'campus': 'North Campus Hub',
        'price': '₹11,000 - ₹18,000',
        'rating': 4.7,
        'tag': 'Premium flats & modern hostels',
        'accent': const Color(0xFFEC4899),
      },
      {
        'area': 'Lajpat Nagar / Amar Colony',
        'campus': 'South Campus Hub',
        'price': '₹12,000 - ₹17,000',
        'rating': 4.5,
        'tag': 'Very family friendly & highly secure',
        'accent': const Color(0xFFF59E0B),
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Outstation Student PG Finder Guide',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Analyze monthly PG/flat rental averages across major Delhi University localities.',
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Hub cards listing
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: hubs.length,
            itemBuilder: (context, index) {
              final h = hubs[index];
              final Color col = h['accent'] as Color;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: col.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: col.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          h['area'] as String,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: col,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: col.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            h['campus'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: col,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      h['tag'] as String,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Average PG Cost / month',
                              style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              h['price'] as String,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(LucideIcons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              h['rating'].toString(),
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              '/5 (Student Rating)',
                              style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Pro-tips advice card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(LucideIcons.shieldCheck, color: Colors.green, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Accommodation Safety Checklist',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildBulletPoint('Verify if security deposit is refundable or mapped to notice parameters.'),
                _buildBulletPoint('Check for active CCTV security gates and guest entry registers.'),
                _buildBulletPoint('Confirm lock-in durations (many standard PGs lock contracts for 11 months).'),
                _buildBulletPoint('Always inspect rooms in person before dispatching booking tokens.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📂 Tab 3: Interactive Directory & Clusters
  Widget _buildDirectoryTab(
    ThemeData theme,
    bool isDark,
    DuCampusService campusService,
    List<CampusGuideItem> filtered,
  ) {
    return Column(
      children: [
        // Search & Filter header
        Container(
          padding: const EdgeInsets.all(16),
          color: isDark ? const Color(0xFF161C24) : Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Search DU Colleges...',
                  prefixIcon: const Icon(LucideIcons.search, size: 20),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0A0E14) : Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Campus Cluster Filter:',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  DropdownButton<String>(
                    value: _selectedCampusFilter,
                    underline: const SizedBox(),
                    items: ['All', 'North', 'South', 'Off'].map((c) {
                      return DropdownMenuItem<String>(
                        value: c,
                        child: Text(
                          c,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCampusFilter = val);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => Provider.of<DuCampusService>(context, listen: false).fetchGuides(),
            child: filtered.isEmpty
                ? const Center(child: Text('No colleges matching criteria.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final g = filtered[index];
                      final Color campusColor = _getCampusColor(g.campusType);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: ExpansionTile(
                          shape: const Border(),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: campusColor.withOpacity(0.1), shape: BoxShape.circle),
                            child: Icon(LucideIcons.school, color: campusColor, size: 20),
                          ),
                          title: Text(
                            g.collegeName,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Row(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: campusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  g.campusType.toUpperCase(),
                                  style: TextStyle(fontSize: 8.5, color: campusColor, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(LucideIcons.star, color: Colors.amber.shade700, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                '${g.safetyIndex} Safety Index',
                                style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Overview Guide:',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    g.description,
                                    style: GoogleFonts.inter(fontSize: 12, height: 1.45, color: Colors.grey.shade800),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Average monthly PG costs:',
                                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                                      ),
                                      Text(
                                        '₹${g.avgPgRent} / month',
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: campusColor),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.checkCircle2, color: Colors.green, size: 14),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLineColor(String line) {
    switch (line.toLowerCase()) {
      case 'yellow':
        return Colors.amber.shade700;
      case 'pink':
        return Colors.pink;
      case 'violet':
        return Colors.purple;
      case 'blue':
      case 'blue branch':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'magenta':
        return Colors.pink.shade300;
      case 'airport express':
        return Colors.orange;
      case 'grey':
        return Colors.grey.shade600;
      default:
        return Colors.grey;
    }
  }

  Color _getCampusColor(String campus) {
    switch (campus.toLowerCase()) {
      case 'north':
        return Colors.indigo;
      case 'south':
        return Colors.green;
      default:
        return Colors.pink;
    }
  }
}
