using System;
using System.Diagnostics;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Speech.Synthesis;
using System.IO;
using System.Linq;

namespace VoiceCommandProcessor
{
    public partial class Form1 : Form
    {
        private TcpListener _listener;
        private CancellationTokenSource _cts;
        private SpeechSynthesizer _speechSynthesizer;
        private bool _isServerRunning = false;

        public Form1()
        {
            InitializeComponent();
            InitializeSpeechSynthesizer();
        }

        private void InitializeSpeechSynthesizer()
        {
            _speechSynthesizer = new SpeechSynthesizer();
            _speechSynthesizer.SetOutputToDefaultAudioDevice();

            // Türkçe ses varsa ayarla
            var voices = _speechSynthesizer.GetInstalledVoices();
            var turkishVoice = voices.FirstOrDefault(v => v.VoiceInfo.Culture.Name.StartsWith("tr"));
            if (turkishVoice != null)
            {
                _speechSynthesizer.SelectVoice(turkishVoice.VoiceInfo.Name);
            }
        }

        private async void StartButton_Click(object sender, EventArgs e)
        {
            if (!_isServerRunning)
            {
                await StartTcpServer();
            }
        }

        private void StopButton_Click(object sender, EventArgs e)
        {
            if (_isServerRunning)
            {
                StopServer();
            }
        }

        private async Task StartTcpServer()
        {
            try
            {
                int port = 5000;
                _listener = new TcpListener(IPAddress.Any, port);
                _listener.Server.ReceiveBufferSize = 16 * 1024;
                _listener.Start();

                _isServerRunning = true;
                UpdateServerStatus("Running", $"TCP Server started on port {port}");

                _cts = new CancellationTokenSource();

                AppendLog($"=== Server Started on Port {port} ===");
                AppendLog($"Local IP: {GetLocalIPAddress()}");

                // Başlangıç sesi
                await SpeakAsync("Sunucu başlatıldı. Komutlar bekleniyor.");

                while (!_cts.Token.IsCancellationRequested)
                {
                    try
                    {
                        var client = await _listener.AcceptTcpClientAsync();
                        _ = Task.Run(() => HandleClientAsync(client));
                    }
                    catch (ObjectDisposedException)
                    {
                        break;
                    }
                }
            }
            catch (Exception ex)
            {
                AppendLog($"Server start error: {ex.Message}");
                UpdateServerStatus("Error", "Failed to start server");
            }
        }

        private async Task HandleClientAsync(TcpClient client)
        {
            string clientEndpoint = client.Client.RemoteEndPoint?.ToString() ?? "Unknown";
            AppendLog($"Client connected: {clientEndpoint}");

            try
            {
                var stream = client.GetStream();
                byte[] buffer = new byte[1024];
                int bytesRead;

                while ((bytesRead = await stream.ReadAsync(buffer, 0, buffer.Length)) != 0)
                {
                    string command = Encoding.UTF8.GetString(buffer, 0, bytesRead).Trim();
                    AppendLog($"Received command: {command}");

                    // Komut işleme
                    await ProcessCommand(command);

                    // Geri bildirim gönder
                    string response = $"Command processed: {command}";
                    byte[] responseData = Encoding.UTF8.GetBytes(response);
                    await stream.WriteAsync(responseData, 0, responseData.Length);
                }
            }
            catch (Exception ex)
            {
                AppendLog($"Client handling error: {ex.Message}");
            }
            finally
            {
                AppendLog($"Client disconnected: {clientEndpoint}");
                client.Close();
            }
        }

        private async Task ProcessCommand(string command)
        {
            try
            {
                command = command.ToLower().Trim();

                // Komut kategorileri
                if (command.Contains("not defteri") || command.Contains("notepad"))
                {
                    Process.Start("notepad.exe");
                    await SpeakAsync("Not defteri açılıyor");
                }
                else if (command.Contains("hesap makinesi") || command.Contains("calculator"))
                {
                    Process.Start("calc.exe");
                    await SpeakAsync("Hesap makinesi açılıyor");
                }
                else if (command.Contains("tarayıcı") || command.Contains("browser") || command.Contains("internet"))
                {
                    Process.Start("chrome.exe");
                    await SpeakAsync("Tarayıcı açılıyor");
                }
                else if (command.Contains("müzik") || command.Contains("music"))
                {
                    // Müzik uygulaması aç
                    try
                    {
                        Process.Start("spotify.exe");
                        await SpeakAsync("Müzik uygulaması açılıyor");
                    }
                    catch
                    {
                        Process.Start("wmplayer.exe");
                        await SpeakAsync("Windows Media Player açılıyor");
                    }
                }
                else if (command.Contains("dosya") || command.Contains("file") || command.Contains("explorer"))
                {
                    Process.Start("explorer.exe");
                    await SpeakAsync("Dosya gezgini açılıyor");
                }
                else if (command.Contains("kapat") || command.Contains("close"))
                {
                    // Aktif pencereyi kapat
                    System.Windows.Forms.SendKeys.SendWait("%{F4}");
                    await SpeakAsync("Pencere kapatılıyor");
                }
                else if (command.Contains("ses aç") || command.Contains("volume up"))
                {
                    AdjustVolume(true);
                    await SpeakAsync("Ses yükseltildi");
                }
                else if (command.Contains("ses kıs") || command.Contains("volume down"))
                {
                    AdjustVolume(false);
                    await SpeakAsync("Ses kısıldı");
                }
                else if (command.Contains("ekran") || command.Contains("screenshot"))
                {
                    TakeScreenshot();
                    await SpeakAsync("Ekran görüntüsü alındı");
                }
                else if (command.Contains("shutdown") || command.Contains("kapat"))
                {
                    await SpeakAsync("Sistem kapatılıyor");
                    await Task.Delay(2000);
                    Process.Start("shutdown", "/s /t 0");
                }
                else if (command.Contains("restart") || command.Contains("yeniden"))
                {
                    await SpeakAsync("Sistem yeniden başlatılıyor");
                    await Task.Delay(2000);
                    Process.Start("shutdown", "/r /t 0");
                }
                else
                {
                    // Bilinmeyen komut
                    await SpeakAsync($"Bilinmeyen komut: {command}");

                    // Komut satırında çalıştırmayı dene
                    try
                    {
                        Process.Start("cmd.exe", $"/c {command}");
                        await SpeakAsync("Komut çalıştırıldı");
                    }
                    catch
                    {
                        await SpeakAsync("Komut çalıştırılamadı");
                    }
                }

                AppendLog($"Command processed: {command}");
            }
            catch (Exception ex)
            {
                AppendLog($"Command processing error: {ex.Message}");
                await SpeakAsync("Komut işlenirken hata oluştu");
            }
        }

        private void AdjustVolume(bool increase)
        {
            try
            {
                if (increase)
                {
                    for (int i = 0; i < 5; i++)
                        System.Windows.Forms.SendKeys.SendWait("{VOLUME_UP}");
                }
                else
                {
                    for (int i = 0; i < 5; i++)
                        System.Windows.Forms.SendKeys.SendWait("{VOLUME_DOWN}");
                }
            }
            catch (Exception ex)
            {
                AppendLog($"Volume adjustment error: {ex.Message}");
            }
        }

        private void TakeScreenshot()
        {
            try
            {
                System.Windows.Forms.SendKeys.SendWait("{PRTSC}");
                // Veya daha gelişmiş screenshot alma
                string desktopPath = Environment.GetFolderPath(Environment.SpecialFolder.Desktop);
                string fileName = $"Screenshot_{DateTime.Now:yyyyMMdd_HHmmss}.png";
                string filePath = Path.Combine(desktopPath, fileName);

                var bounds = Screen.PrimaryScreen.Bounds;
                using (var bitmap = new System.Drawing.Bitmap(bounds.Width, bounds.Height))
                using (var graphics = System.Drawing.Graphics.FromImage(bitmap))
                {
                    graphics.CopyFromScreen(bounds.X, bounds.Y, 0, 0, bounds.Size);
                    bitmap.Save(filePath, System.Drawing.Imaging.ImageFormat.Png);
                }

                AppendLog($"Screenshot saved: {filePath}");
            }
            catch (Exception ex)
            {
                AppendLog($"Screenshot error: {ex.Message}");
            }
        }

        private async Task SpeakAsync(string text)
        {
            try
            {
                await Task.Run(() => _speechSynthesizer.Speak(text));
            }
            catch (Exception ex)
            {
                AppendLog($"Speech error: {ex.Message}");
            }
        }

        private string GetLocalIPAddress()
        {
            try
            {
                string localIP = "";
                using (Socket socket = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, 0))
                {
                    socket.Connect("8.8.8.8", 65530);
                    IPEndPoint endPoint = socket.LocalEndPoint as IPEndPoint;
                    localIP = endPoint.Address.ToString();
                }
                return localIP;
            }
            catch (Exception ex)
            {
                AppendLog($"IP address detection error: {ex.Message}");
                return "Unknown";
            }
        }

        private void UpdateServerStatus(string status, string message)
        {
            if (InvokeRequired)
            {
                Invoke(new Action(() => UpdateServerStatus(status, message)));
                return;
            }

            _statusLabel.Text =_statusLabel.Text + $" {status}";
            _statusLabel.ForeColor = status == "Başarılı" ? System.Drawing.Color.Green :
                                   status == "Error" ? System.Drawing.Color.Red :
                                   System.Drawing.Color.Gray;

            _startButton.Enabled = !_isServerRunning;
            _stopButton.Enabled = _isServerRunning;

            AppendLog(message);
        }

        private void AppendLog(string text)
        {
            if (InvokeRequired)
            {
                Invoke(new Action(() => AppendLog(text)));
                return;
            }

            string timestamp = DateTime.Now.ToString("HH:mm:ss");
            _logTextBox.AppendText($"[{timestamp}] {text}\r\n");
            _logTextBox.ScrollToCaret();

            // Log dosyasına da yaz
            try
            {
                string logFile = Path.Combine(Application.StartupPath, "command_log.txt");
                File.AppendAllText(logFile, $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] {text}\r\n");
            }
            catch { }
        }

        private void StopServer()
        {
            try
            {
                _isServerRunning = false;
                _cts?.Cancel();
                _listener?.Stop();

                UpdateServerStatus("Stopped", "Server stopped");

                Task.Run(async () => await SpeakAsync("Sunucu durduruldu"));
            }
            catch (Exception ex)
            {
                AppendLog($"Server stop error: {ex.Message}");
            }
        }

        private void Form1_FormClosing(object sender, FormClosingEventArgs e)
        {
            StopServer();
            _speechSynthesizer?.Dispose();
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            AppendLog("Voice Command Processor initialized");
            AppendLog("Click 'Start Server' to begin listening for commands");

            // Otomatik başlat
            Task.Run(async () => {
                await Task.Delay(1000);
                if (InvokeRequired)
                {
                    Invoke(new Action(() => StartButton_Click(null, null)));
                }
            });
        }
    }
}