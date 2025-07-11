import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

void main() {
  runApp(const NexronPCController());
}

class NexronPCController extends StatelessWidget {
  const NexronPCController({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexron PC Controller',
      debugShowCheckedModeBanner: false,
      theme: _buildDarkTheme(),
      home: const VoiceCommandPage(),
    );
  }

  ThemeData _buildDarkTheme() {
    const Color primaryColor = Color(0xFF1E88E5);
    const Color surfaceColor = Color(0xFF1E1E1E);
    const Color cardColor = Color(0xFF2A2A2A);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: const Color(0xFF64B5F6),
        surface: surfaceColor,
        background: const Color(0xFF121212),
        error: const Color(0xFFCF6679),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 8,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      // Diğer tema ayarları...
    );
  }
}

class VoiceCommandPage extends StatefulWidget {
  const VoiceCommandPage({super.key});

  @override
  State<VoiceCommandPage> createState() => _VoiceCommandPageState();
}

class _VoiceCommandPageState extends State<VoiceCommandPage>
    with TickerProviderStateMixin {
  // Servisler
  final NetworkInfo _networkInfo = NetworkInfo();
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _textToSpeech = FlutterTts();

  // Durum değişkenleri
  String? _localIp;
  String? _subnet;
  String? _selectedPcIp;
  Socket? _socket;
  List<String> _activeIpAddresses = [];
  bool _isScanning = false;
  bool _isListening = false;
  bool _isSpeechEnabled = false;
  String _lastWords = '';
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  final List<String> _commandHistory = [];
  final TextEditingController _manualCommandController =
      TextEditingController();

  // Animasyonlar
  late AnimationController _listeningAnimationController;
  late AnimationController _connectionAnimationController;
  late Animation<double> _listeningAnimation;
  late Animation<double> _connectionAnimation;

  // Timer'lar
  Timer? _connectionCheckTimer;
  Timer? _speechTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeApp();
  }

  void _initAnimations() {
    _listeningAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _connectionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _listeningAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _listeningAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _connectionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _connectionAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _listeningAnimationController.repeat(reverse: true);
  }

  Future<void> _initializeApp() async {
    try {
      await _requestPermissions();
      await _initSpeech();
      await _initTTS();
      await _initNetworkInfo();
    } catch (e, stack) {
      _logError('App initialization error', e, stack);
      _showSnackBar('Initialization error: ${e.toString()}');
    }
  }

  Future<void> _requestPermissions() async {
    final statuses = await [
      Permission.microphone,
      Permission.speech,
      Permission.bluetooth,
      Permission.bluetoothConnect,
    ].request();

    if (statuses.values.any((status) => status.isDenied)) {
      _showSnackBar('Required permissions not granted');
    }
  }

  Future<void> _initSpeech() async {
    try {
      final isAvailable = await _speechToText.initialize(
        onError: (error) => _logError('Speech error', error.errorMsg),
        onStatus: (status) => debugPrint('Speech status: $status'),
      );
      setState(() => _isSpeechEnabled = isAvailable);
    } catch (e, stack) {
      _logError('Speech init error', e, stack);
      _showSnackBar('Speech service unavailable');
    }
  }

  Future<void> _initTTS() async {
    try {
      await _textToSpeech.setLanguage('tr-TR');
      await _textToSpeech.setSpeechRate(0.6);
      await _textToSpeech.setVolume(0.8);
      await _textToSpeech.setPitch(1.0);
    } catch (e, stack) {
      _logError('TTS init error', e, stack);
    }
  }

  Future<void> _initNetworkInfo() async {
    try {
      final ip = await _networkInfo.getWifiIP();
      if (ip == null) {
        _showSnackBar('No WiFi connection detected');
        return;
      }

      setState(() {
        _localIp = ip;
        _subnet = _extractSubnet(ip);
      });

      await _scanNetwork();
    } catch (e, stack) {
      _logError('Network info error', e, stack);
      _showSnackBar('Network info unavailable');
    }
  }

  String _extractSubnet(String ip) {
    final parts = ip.split('.');
    return parts.length == 4 ? '${parts[0]}.${parts[1]}.${parts[2]}.' : '';
  }

  Future<void> _scanNetwork() async {
    if (_subnet == null) return;

    setState(() {
      _isScanning = true;
      _activeIpAddresses = [];
    });

    try {
      final List<Future> futures = [];
      for (int i = 1; i <= 254; i++) {
        final testIp = '$_subnet$i';
        futures.add(_pingIp(testIp));
      }

      await Future.wait(futures);

      HapticFeedback.lightImpact();
      await _speak(
        'Scan complete. Found ${_activeIpAddresses.length} devices.',
      );
    } catch (e, stack) {
      _logError('Network scan error', e, stack);
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _pingIp(String ip) async {
    try {
      final result = await Process.run('ping', [
        '-c',
        '1',
        '-W',
        '1',
        ip,
      ], runInShell: true).timeout(const Duration(seconds: 2));

      if (result.exitCode == 0) {
        setState(() => _activeIpAddresses = [..._activeIpAddresses, ip]);
      }
    } catch (e) {
      debugPrint('Ping error ($ip): $e');
    }
  }

  Future<void> _connectToPc(String ip) async {
    if (_connectionStatus == ConnectionStatus.connecting) return;

    setState(() {
      _connectionStatus = ConnectionStatus.connecting;
      _connectionAnimationController.reset();
      _connectionAnimationController.forward();
    });

    try {
      _socket = await Socket.connect(
        ip,
        5000,
      ).timeout(const Duration(seconds: 5));

      _socket!.listen(
        (data) => debugPrint('PC Response: ${utf8.decode(data)}'),
        onError: (error) {
          _logError('Socket error', error);
          _disconnect();
        },
        onDone: () {
          _showSnackBar('Connection closed');
          _disconnect();
        },
      );

      setState(() {
        _selectedPcIp = ip;
        _connectionStatus = ConnectionStatus.connected;
      });

      _connectionCheckTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _checkConnection(),
      );

      HapticFeedback.mediumImpact();
      await _speak('Connected to PC successfully');
      _showSnackBar('Connected to: $ip', SnackBarType.success);
    } catch (e, stack) {
      _logError('Connection error', e, stack);
      _showSnackBar('Connection failed', SnackBarType.error);
      _disconnect();
    }
  }

  void _disconnect() {
    _connectionCheckTimer?.cancel();
    _socket?.destroy();
    setState(() {
      _socket = null;
      _selectedPcIp = null;
      _connectionStatus = ConnectionStatus.disconnected;
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _checkConnection() async {
    if (_socket == null) return;

    try {
      _socket!.add(utf8.encode('ping'));
    } catch (e) {
      _disconnect();
    }
  }

  Future<void> _sendCommand(String command) async {
    if (_socket == null) {
      _showSnackBar('Not connected to PC', SnackBarType.warning);
      return;
    }

    final trimmedCmd = command.trim();
    if (trimmedCmd.isEmpty) {
      _showSnackBar('Empty command', SnackBarType.warning);
      return;
    }

    try {
      _socket!.add(utf8.encode(trimmedCmd));

      setState(() {
        _commandHistory.insert(0, trimmedCmd);
        if (_commandHistory.length > 20) {
          _commandHistory.removeRange(20, _commandHistory.length);
        }
      });

      HapticFeedback.lightImpact();
      await _speak('Command sent');
      _showSnackBar('Command sent: $trimmedCmd', SnackBarType.success);
    } catch (e, stack) {
      _logError('Command send error', e, stack);
      _showSnackBar('Failed to send command', SnackBarType.error);
    }
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty) return;

    try {
      await _textToSpeech.speak(text);
    } catch (e, stack) {
      _logError('TTS error', e, stack);
    }
  }

  Future<void> _startListening() async {
    if (!_isSpeechEnabled) {
      _showSnackBar('Speech recognition not available', SnackBarType.warning);
      return;
    }

    try {
      setState(() => _isListening = true);
      _lastWords = '';

      _speechTimeoutTimer = Timer(const Duration(seconds: 15), _stopListening);

      await _speechToText.listen(
        onResult: _processSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
        localeId: 'tr_TR',
      );

      HapticFeedback.mediumImpact();
    } catch (e, stack) {
      _logError('Speech listening error', e, stack);
      _stopListening();
    }
  }

  void _stopListening() {
    _speechTimeoutTimer?.cancel();
    _speechToText.stop();
    setState(() => _isListening = false);
    HapticFeedback.lightImpact();
  }

  void _processSpeechResult(SpeechRecognitionResult result) {
    setState(() => _lastWords = result.recognizedWords);

    if (result.finalResult && result.recognizedWords.isNotEmpty) {
      _sendCommand(result.recognizedWords);
      _stopListening();
    }
  }

  void _showSnackBar(String message, [SnackBarType type = SnackBarType.info]) {
    if (!mounted) return;

    final colors = Theme.of(context).colorScheme;
    Color backgroundColor;
    IconData icon;

    switch (type) {
      case SnackBarType.success:
        backgroundColor = colors.primary;
        icon = Icons.check_circle;
        break;
      case SnackBarType.error:
        backgroundColor = colors.error;
        icon = Icons.error;
        break;
      case SnackBarType.warning:
        backgroundColor = Colors.orange;
        icon = Icons.warning;
        break;
      case SnackBarType.info:
      default:
        backgroundColor = colors.secondary;
        icon = Icons.info;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _logError(String message, dynamic error, [StackTrace? stack]) {
    debugPrint('$message: $error');
    if (stack != null) debugPrint(stack.toString());
  }

  @override
  void dispose() {
    _disconnect();
    _connectionCheckTimer?.cancel();
    _speechTimeoutTimer?.cancel();
    _speechToText.stop();
    _textToSpeech.stop();
    _manualCommandController.dispose();
    _listeningAnimationController.dispose();
    _connectionAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nexron PC Controller'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _scanNetwork,
            tooltip: 'Refresh Network',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildNetworkCard(),
            const SizedBox(height: 16),
            _buildConnectionCard(),
            const SizedBox(height: 16),
            _buildDevicesCard(),
            const SizedBox(height: 16),
            _buildVoiceCommandCard(),
            const SizedBox(height: 16),
            _buildManualCommandCard(),
            if (_commandHistory.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildCommandHistoryCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Network Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_localIp != null) ...[
              _buildInfoRow('Local IP', _localIp!),
              const SizedBox(height: 8),
              _buildInfoRow('Subnet', _subnet ?? ''),
            ] else
              const Text('Loading network info...'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isScanning ? null : _scanNetwork,
                icon: _isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(_isScanning ? 'Scanning...' : 'Scan Network'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard() {
    final colors = Theme.of(context).colorScheme;
    Color cardColor;
    IconData icon;
    String statusText;

    switch (_connectionStatus) {
      case ConnectionStatus.connected:
        cardColor = colors.primary.withOpacity(0.1);
        icon = Icons.check_circle;
        statusText = 'Connected: $_selectedPcIp';
        break;
      case ConnectionStatus.connecting:
        cardColor = Colors.orange.withOpacity(0.1);
        icon = Icons.sync;
        statusText = 'Connecting...';
        break;
      case ConnectionStatus.disconnected:
      default:
        cardColor = colors.error.withOpacity(0.1);
        icon = Icons.error_outline;
        statusText = 'Disconnected';
    }

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _connectionStatus == ConnectionStatus.connecting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(icon, color: _getConnectionColor()),
                const SizedBox(width: 8),
                const Text(
                  'Connection Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 16,
                color: _getConnectionColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_connectionStatus == ConnectionStatus.connected) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _disconnect,
                icon: const Icon(Icons.close),
                label: const Text('Disconnect'),
                style: ElevatedButton.styleFrom(backgroundColor: colors.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getConnectionColor() {
    switch (_connectionStatus) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.disconnected:
      default:
        return Colors.red;
    }
  }

  Widget _buildDevicesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Discovered Devices',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_activeIpAddresses.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No devices found'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _activeIpAddresses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final ip = _activeIpAddresses[index];
                  final isSelected = ip == _selectedPcIp;

                  return ListTile(
                    leading: Icon(
                      Icons.computer,
                      color: isSelected ? Colors.blue : Colors.grey,
                    ),
                    title: Text(
                      ip,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(isSelected ? 'Connected' : 'Tap to connect'),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.arrow_forward_ios),
                    onTap: isSelected ? null : () => _connectToPc(ip),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: isSelected
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.05),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceCommandCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Voice Command',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Text(
                _lastWords.isEmpty ? 'Tap microphone to speak' : _lastWords,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AnimatedBuilder(
                  animation: _listeningAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isListening ? _listeningAnimation.value : 1.0,
                      child: FloatingActionButton.extended(
                        onPressed: _isListening
                            ? _stopListening
                            : _startListening,
                        backgroundColor: _isListening
                            ? Colors.red
                            : Colors.blue,
                        icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                        label: Text(_isListening ? 'Stop' : 'Speak'),
                      ),
                    );
                  },
                ),
                FloatingActionButton.extended(
                  onPressed: _lastWords.isEmpty
                      ? null
                      : () => _sendCommand(_lastWords),
                  backgroundColor: Colors.green,
                  icon: const Icon(Icons.send),
                  label: const Text('Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualCommandCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manual Command',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _manualCommandController,
              decoration: const InputDecoration(
                hintText: 'Enter your command...',
                prefixIcon: Icon(Icons.edit),
              ),
              maxLines: 3,
              minLines: 1,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _sendCommand(value);
                  _manualCommandController.clear();
                }
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final cmd = _manualCommandController.text;
                  if (cmd.isNotEmpty) {
                    _sendCommand(cmd);
                    _manualCommandController.clear();
                  }
                },
                icon: const Icon(Icons.send),
                label: const Text('Send Command'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Command History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _commandHistory.clear()),
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _commandHistory.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final cmd = _commandHistory[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.2),
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    cmd,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text('Tap to resend'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: cmd));
                          _showSnackBar('Command copied', SnackBarType.success);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.replay),
                        onPressed: () => _sendCommand(cmd),
                      ),
                    ],
                  ),
                  onTap: () => _sendCommand(cmd),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

enum ConnectionStatus { connected, connecting, disconnected }

enum SnackBarType { success, error, warning, info }
