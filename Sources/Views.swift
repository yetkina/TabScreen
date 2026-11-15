import SwiftUI

enum Page: String, CaseIterable, Identifiable {
    case dashboard, setup, guide, about
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.67percent"
        case .setup: return "wand.and.stars"
        case .guide: return "questionmark.circle.fill"
        case .about: return "info.circle.fill"
        }
    }
    @MainActor func title(_ m: AppModel) -> String {
        switch self {
        case .dashboard: return m.t("Control", "Kontrol")
        case .setup: return m.t("Setup", "Kurulum")
        case .guide: return m.t("How-to & Help", "Nasıl Yapılır & Yardım")
        case .about: return m.t("About", "Hakkında")
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var m: AppModel
    @State private var page: Page = .dashboard

    var body: some View {
        NavigationSplitView {
            List(Page.allCases, selection: $page) { p in
                Label(p.title(m), systemImage: p.symbol).tag(p)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
            .safeAreaInset(edge: .bottom) {
                Picker("", selection: $m.lang) {
                    Text("Auto").tag("auto")
                    Text("English").tag("en")
                    Text("Türkçe").tag("tr")
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .padding(10)
            }
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch page {
                    case .dashboard: DashboardView()
                    case .setup: SetupView()
                    case .guide: GuideView()
                    case .about: AboutView()
                    }
                }
                .padding(24)
                .frame(maxWidth: 820, alignment: .leading)
            }
            .overlay(alignment: .bottom) { if m.busy { BusyBar() } }
        }
    }
}

struct BusyBar: View {
    @EnvironmentObject var m: AppModel
    var body: some View {
        HStack(spacing: 10) {
            ProgressView().controlSize(.small)
            Text(m.busyTitle).font(.callout)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(.regularMaterial, in: Capsule())
        .shadow(radius: 6)
        .padding(.bottom, 14)
    }
}

// MARK: - Small building blocks
struct Card<Content: View>: View {
    var content: Content
    init(@ViewBuilder _ c: () -> Content) { content = c() }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.primary.opacity(0.05)))
    }
}

struct HeaderView: View {
    var symbol: String; var title: String; var subtitle: String; var tint: Color = .accentColor
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).font(.system(size: 30, weight: .semibold)).foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(RoundedRectangle(cornerRadius: 14).fill(tint.gradient))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.title2.bold())
                Text(subtitle).foregroundStyle(.secondary)
            }
        }
    }
}

struct MessageBanner: View {
    @EnvironmentObject var m: AppModel
    var body: some View {
        if let msg = m.message {
            HStack(alignment: .top) {
                Image(systemName: "info.circle.fill").foregroundStyle(.blue)
                Text(msg)
                Spacer()
                Button { m.message = nil } label: { Image(systemName: "xmark") }.buttonStyle(.plain)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue.opacity(0.12)))
        }
    }
}

// MARK: - Dashboard
struct DashboardView: View {
    @EnvironmentObject var m: AppModel
    @State private var showLog = false

    var body: some View {
        HeaderView(symbol: "display.2", title: "TabScreen",
                   subtitle: m.t("Use your Android tablet as a second Mac screen", "Android tabletinizi Mac'in ikinci ekranı yapın"),
                   tint: .indigo)
        MessageBanner()

        Card {
            HStack(spacing: 14) {
                Circle().fill(m.sunshineRunning ? Color.green : Color.red).frame(width: 16, height: 16)
                    .shadow(color: (m.sunshineRunning ? Color.green : Color.red).opacity(0.7), radius: 6)
                VStack(alignment: .leading) {
                    Text(m.sunshineRunning ? m.t("Sunshine is running", "Sunshine çalışıyor")
                                           : (m.sunshineInstalled ? m.t("Sunshine is stopped", "Sunshine durdu")
                                                                  : m.t("Sunshine is not installed", "Sunshine kurulu değil")))
                        .font(.title3.bold())
                    Text(m.sunshineRunning ? m.t("Your tablet can connect now.", "Tabletiniz artık bağlanabilir.")
                                           : m.t("Start it to connect your tablet.", "Tableti bağlamak için başlatın."))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            HStack(spacing: 10) {
                BigButton(symbol: "play.fill", title: m.t("Start", "Başlat"), tint: .green,
                          enabled: m.sunshineInstalled && !m.sunshineRunning && !m.busy) { Task { await m.start() } }
                BigButton(symbol: "arrow.clockwise", title: m.t("Restart", "Yeniden başlat"), tint: .orange,
                          enabled: m.sunshineInstalled && !m.busy) { Task { await m.restart() } }
                BigButton(symbol: "stop.fill", title: m.t("Stop", "Durdur"), tint: .red,
                          enabled: m.sunshineRunning && !m.busy) { Task { await m.stop() } }
            }
            Divider()
            Toggle(isOn: Binding(get: { m.autostart }, set: { v in Task { await m.setAutostart(v) } })) {
                Label(m.t("Start Sunshine automatically when I log in", "Giriş yaptığımda Sunshine otomatik başlasın"),
                      systemImage: "power.circle.fill")
            }
            .disabled(!m.sunshineInstalled || m.busy)
            .toggleStyle(.switch)
        }

        Card {
            Label(m.t("Tablet connection", "Tablet bağlantısı"), systemImage: "ipad.and.arrow.forward").font(.headline)
            HStack {
                Text(m.t("Mac IP address:", "Mac IP adresi:")).foregroundStyle(.secondary)
                Text(m.ip).font(.system(.body, design: .monospaced).bold()).textSelection(.enabled)
                Button { m.copy(m.ip) } label: { Image(systemName: "doc.on.doc") }.buttonStyle(.borderless)
                Spacer()
            }
            Text(m.t("Enter this IP in Moonlight on your tablet (same Wi-Fi network).",
                     "Bu IP'yi tabletinizdeki Moonlight'a girin (aynı Wi-Fi ağı)."))
                .font(.callout).foregroundStyle(.secondary)
            HStack {
                Button { m.openWebUI() } label: { Label(m.t("Open Sunshine web UI (PIN, password)", "Sunshine web arayüzü (PIN, şifre)"), systemImage: "safari") }
                Button { m.openURL("https://play.google.com/store/apps/details?id=com.limelight") } label: {
                    Label(m.t("Get Moonlight (Android)", "Moonlight indir (Android)"), systemImage: "arrow.down.app")
                }
            }
        }

        Card {
            Label(m.t("Screen to stream", "Yayınlanacak ekran"), systemImage: "display").font(.headline)
            ForEach(m.displays) { d in
                HStack {
                    Image(systemName: m.configuredOutput == d.id ? "largecircle.fill.circle" : "circle")
                        .foregroundStyle(m.configuredOutput == d.id ? Color.accentColor : .secondary)
                    VStack(alignment: .leading) {
                        Text("\(d.name)").fontWeight(.medium)
                        Text("ID \(d.id) · \(d.width)×\(d.height)\(d.isMain ? " · " + m.t("main", "ana") : "")\(d.looksVirtual ? " · " + m.t("virtual", "sanal") : "")")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if m.configuredOutput != d.id {
                        Button(m.t("Use this", "Bunu kullan")) { Task { await m.writeOutput(d.id) } }
                    }
                }
            }
            if m.configuredOutput == nil {
                Text(m.t("No screen selected: Sunshine will stream your main monitor.", "Ekran seçilmedi: Sunshine ana monitörünüzü yayınlar."))
                    .font(.callout).foregroundStyle(.orange)
            }
            if m.displays.count < 2 {
                Text(m.t("Only one display found. Create a virtual display in Crisp.", "Yalnızca bir ekran bulundu. Crisp'te sanal ekran oluşturun."))
                    .font(.callout).foregroundStyle(.orange)
            }
        }

        DisclosureGroup(isExpanded: $showLog) {
            Text(m.log.isEmpty ? m.t("Nothing yet.", "Henüz bir şey yok.") : m.log)
                .font(.system(size: 11, design: .monospaced)).textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack {
                Button(m.t("Open Sunshine log", "Sunshine günlüğünü aç")) { m.openLogFile() }
                Button(m.t("Clear", "Temizle")) { m.log = "" }
            }
        } label: { Label(m.t("Activity log", "Etkinlik günlüğü"), systemImage: "terminal") }
    }
}

struct BigButton: View {
    var symbol: String; var title: String; var tint: Color; var enabled: Bool; var action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: symbol).font(.system(size: 22, weight: .bold))
                Text(title).font(.callout.weight(.medium))
            }
            .frame(maxWidth: .infinity, minHeight: 62)
            .foregroundStyle(.white)
            .background(RoundedRectangle(cornerRadius: 12).fill(tint.gradient))
            .opacity(enabled ? 1 : 0.35)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

// MARK: - Setup
struct StepRow: View {
    var ok: Bool; var symbol: String; var title: String; var detail: String
    var actions: [(String, () -> Void)] = []
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.title2).foregroundStyle(ok ? Color.green : Color.orange)
            VStack(alignment: .leading, spacing: 4) {
                Label(title, systemImage: symbol).font(.headline)
                Text(detail).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                if !actions.isEmpty {
                    HStack { ForEach(actions.indices, id: \.self) { i in Button(actions[i].0, action: actions[i].1) } }
                }
            }
            Spacer()
        }
    }
}

struct SetupView: View {
    @EnvironmentObject var m: AppModel
    @State private var user = ""
    @State private var pass = ""

    var body: some View {
        HeaderView(symbol: "wand.and.stars", title: m.t("Setup", "Kurulum"),
                   subtitle: m.t("Checks what is missing and installs it for you", "Eksikleri kontrol eder ve sizin için kurar"), tint: .purple)
        MessageBanner()

        Card {
            Text(m.t("One click does everything it can: installs missing apps with Homebrew, picks the virtual display, writes the Sunshine config and starts it.",
                     "Tek tıkla yapabildiği her şeyi yapar: eksik uygulamaları Homebrew ile kurar, sanal ekranı seçer, Sunshine ayarını yazar ve başlatır."))
                .foregroundStyle(.secondary)
            Button { Task { await m.autoSetup() } } label: {
                Label(m.t("Auto setup", "Otomatik kurulum"), systemImage: "sparkles").font(.headline).frame(maxWidth: .infinity, minHeight: 34)
            }
            .buttonStyle(.borderedProminent).controlSize(.large).disabled(m.busy)
        }

        Card {
            StepRow(ok: m.brewInstalled, symbol: "shippingbox", title: "Homebrew",
                    detail: m.brewInstalled ? m.t("Installed.", "Kurulu.")
                        : m.t("Needed to install the other apps automatically. Install it first:", "Diğer uygulamaları otomatik kurmak için gerekir. Önce kurun:"),
                    actions: m.brewInstalled ? [] : [
                        (m.t("Install in Terminal", "Terminal'de kur"), { m.openTerminalWithBrewInstall() }),
                        (m.t("Copy command", "Komutu kopyala"), { m.copy(AppModel.brewInstallCommand) }),
                        (m.t("brew.sh", "brew.sh"), { m.openURL("https://brew.sh") })])
            if !m.brewInstalled {
                Text(AppModel.brewInstallCommand).font(.system(size: 11, design: .monospaced)).textSelection(.enabled)
                    .padding(8).background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.07)))
            }
            Divider()
            StepRow(ok: m.sunshineInstalled, symbol: "sun.max.fill", title: "Sunshine",
                    detail: m.sunshineInstalled ? m.t("Installed.", "Kurulu.")
                        : m.t("Streaming server that sends your virtual display to the tablet.",
                              "Sanal ekranınızı tablete gönderen yayın sunucusu."),
                    actions: m.sunshineInstalled ? [] : [
                        (m.t("Install with Homebrew", "Homebrew ile kur"), { Task { await m.installSunshine() } }),
                        (m.t("Copy brew command", "brew komutunu kopyala"), { m.copy("brew tap \(AppModel.tap) && brew install \(AppModel.formula)") }),
                        (m.t("Other install options", "Diğer kurulum yolları"), { m.openURL("https://docs.lizardbyte.dev/projects/sunshine/latest/md_docs_2getting__started.html") }),
                        (m.t("GitHub releases", "GitHub sürümleri"), { m.openURL("https://github.com/LizardByte/Sunshine/releases") })])
            Divider()
            StepRow(ok: m.crispInstalled, symbol: "display.2", title: "Crisp",
                    detail: m.crispInstalled ? m.t("Installed. Use it to create a virtual display.", "Kurulu. Sanal ekran oluşturmak için kullanın.")
                        : m.t("Creates the virtual display. Alternative: BetterDisplay.", "Sanal ekranı oluşturur. Alternatif: BetterDisplay."),
                    actions: m.crispInstalled ? [] : [
                        (m.t("Install Crisp", "Crisp'i kur"), { Task { await m.installCrisp() } }),
                        (m.t("Install BetterDisplay instead", "Bunun yerine BetterDisplay kur"),
                         { Task { await m.installCask("betterdisplay", title: m.t("Installing BetterDisplay", "BetterDisplay kuruluyor")) } }),
                        (m.t("Website", "Web sitesi"), { m.openURL("https://crispmac.app/") })])
            Divider()
            StepRow(ok: m.displays.count >= 2, symbol: "rectangle.on.rectangle", title: m.t("Virtual display", "Sanal ekran"),
                    detail: m.displays.count >= 2 ? m.t("Found: \(m.displays.map { $0.name }.joined(separator: ", "))", "Bulundu: \(m.displays.map { $0.name }.joined(separator: ", "))")
                        : m.t("Open Crisp and create a virtual display. Tip: 1920×1200 matches the Galaxy Tab A11+.",
                              "Crisp'i açıp sanal ekran oluşturun. İpucu: 1920×1200 Galaxy Tab A11+ ile birebir uyuşur."),
                    actions: [(m.t("Display settings", "Ekran ayarları"), { m.openDisplaysSettings() })])
            Divider()
            StepRow(ok: m.configuredOutput != nil && m.displays.contains(where: { $0.id == m.configuredOutput }),
                    symbol: "arrow.triangle.branch", title: m.t("Sunshine uses the virtual display", "Sunshine sanal ekranı kullanıyor"),
                    detail: m.configuredOutput.map { m.t("output_name = \($0)", "output_name = \($0)") }
                        ?? m.t("Not configured yet.", "Henüz ayarlanmadı."),
                    actions: m.suggestedDisplay.map { d in
                        [(m.t("Use \(d.name) (ID \(d.id))", "\(d.name) (ID \(d.id)) kullan"), { Task { await m.writeOutput(d.id) } })]
                    } ?? [])
        }

        Card {
            Label(m.t("Things only you can approve", "Yalnızca sizin onaylayabileceğiniz şeyler"), systemImage: "hand.raised.fill").font(.headline)
            Text(m.t("macOS does not let apps grant these. Add Sunshine to both lists.", "macOS bu izinleri uygulamaların vermesine izin vermez. Sunshine'ı iki listeye de ekleyin."))
                .font(.callout).foregroundStyle(.secondary)
            HStack {
                Button { m.openScreenRecordingSettings() } label: { Label(m.t("Screen Recording", "Ekran Kaydı"), systemImage: "record.circle") }
                Button { m.openAccessibilitySettings() } label: { Label(m.t("Accessibility", "Erişilebilirlik"), systemImage: "accessibility") }
            }
            Divider()
            Text(m.t("Web UI login (first time only)", "Web arayüzü girişi (yalnızca ilk kez)")).font(.subheadline.bold())
            HStack {
                TextField(m.t("Username", "Kullanıcı adı"), text: $user).textFieldStyle(.roundedBorder)
                SecureField(m.t("Password", "Şifre"), text: $pass).textFieldStyle(.roundedBorder)
                Button(m.t("Save", "Kaydet")) { Task { await m.setCredentials(user: user, password: pass); pass = "" } }
                    .disabled(user.isEmpty || pass.isEmpty || !m.sunshineInstalled)
            }
        }
    }
}

// MARK: - Guide
struct GuideItem: Identifiable {
    let id = UUID()
    let scene: String
    let title: String
    let steps: [String]
    var actions: [(String, () -> Void)] = []
}

struct GuideView: View {
    @EnvironmentObject var m: AppModel

    var quickStart: [GuideItem] {
        [
            GuideItem(scene: "setup", title: m.t("1. Install the tools", "1. Araçları kurun"),
                      steps: [m.t("Open Setup and press Auto setup (Sunshine + Crisp).", "Kurulum sayfasında Otomatik kurulum'a basın (Sunshine + Crisp).")]),
            GuideItem(scene: "virtual", title: m.t("2. Create the virtual display", "2. Sanal ekranı oluşturun"),
                      steps: [m.t("Open Crisp from the menu bar and add a virtual display.", "Menü çubuğundan Crisp'i açıp sanal ekran ekleyin."),
                              m.t("Pick 1920×1200 (tablet resolution), HiDPI off.", "1920×1200 seçin (tablet çözünürlüğü), HiDPI kapalı.")]),
            GuideItem(scene: "permissions", title: m.t("3. Allow Sunshine", "3. Sunshine'a izin verin"),
                      steps: [m.t("System Settings → Privacy & Security → Screen Recording and Accessibility → enable Sunshine.", "Sistem Ayarları → Gizlilik ve Güvenlik → Ekran Kaydı ve Erişilebilirlik → Sunshine'ı açın.")],
                      actions: [(m.t("Screen Recording", "Ekran Kaydı"), { m.openScreenRecordingSettings() }),
                                (m.t("Accessibility", "Erişilebilirlik"), { m.openAccessibilitySettings() })]),
            GuideItem(scene: "pairing", title: m.t("4. Pair the tablet", "4. Tableti eşleştirin"),
                      steps: [m.t("Install Moonlight on the tablet and connect it to the same Wi-Fi (5 GHz).", "Tabletinize Moonlight kurun ve aynı Wi-Fi'ye (5 GHz) bağlayın."),
                              m.t("Add the Mac's IP (\(m.ip)). Moonlight shows a PIN.", "Mac'in IP'sini (\(m.ip)) ekleyin. Moonlight bir PIN gösterir."),
                              m.t("Enter the PIN in Sunshine web UI → PIN tab.", "PIN'i Sunshine web arayüzü → PIN sekmesine girin.")],
                      actions: [(m.t("Open web UI", "Web arayüzünü aç"), { m.openWebUI() })]),
            GuideItem(scene: "connected", title: m.t("5. Tap “Desktop”", "5. “Desktop”a dokunun"),
                      steps: [m.t("Your virtual display now appears on the tablet. Drag windows onto it.", "Sanal ekranınız tablette görünür. Pencereleri üzerine sürükleyin."),
                              m.t("Moonlight settings: 1920×1200, 60 FPS, 30–50 Mbps, HEVC on.", "Moonlight ayarları: 1920×1200, 60 FPS, 30–50 Mbps, HEVC açık.")]),
        ]
    }

    var trouble: [GuideItem] {
        [
            GuideItem(scene: "nosignal", title: m.t("Tablet can't find or reach the Mac", "Tablet Mac'i bulamıyor veya ulaşamıyor"),
                      steps: [m.t("Check Sunshine is running (Control page).", "Sunshine'ın çalıştığını kontrol edin (Kontrol sayfası)."),
                              m.t("Mac and tablet must be on the same Wi-Fi/network. Turn VPNs off.", "Mac ve tablet aynı Wi-Fi/ağda olmalı. VPN'leri kapatın."),
                              m.t("In Moonlight tap “+” and type the IP manually: \(m.ip).", "Moonlight'ta “+” ile IP'yi elle yazın: \(m.ip)."),
                              m.t("Guest/“client isolation” Wi-Fi blocks devices from seeing each other.", "Misafir ağı/“istemci yalıtımı” cihazların birbirini görmesini engeller.")],
                      actions: [(m.t("Restart Sunshine", "Sunshine'ı yeniden başlat"), { Task { await m.restart() } })]),
            GuideItem(scene: "samenet", title: m.t("Pairing / PIN fails", "Eşleştirme / PIN hatası"),
                      steps: [m.t("Open the web UI and use the PIN tab while Moonlight shows the PIN.", "Moonlight PIN gösterirken web arayüzünde PIN sekmesini kullanın."),
                              m.t("Enter it quickly, it expires. Restart Sunshine and try again.", "Hızlı girin, süresi dolar. Sunshine'ı yeniden başlatıp tekrar deneyin."),
                              m.t("Browser warning about the certificate is normal: continue.", "Tarayıcının sertifika uyarısı normaldir: devam edin.")],
                      actions: [(m.t("Open web UI", "Web arayüzünü aç"), { m.openWebUI() })]),
            GuideItem(scene: "black", title: m.t("Black screen, or the main monitor is shown", "Siyah ekran veya ana monitör görünüyor"),
                      steps: [m.t("Make sure the virtual display exists and Sunshine uses it (Control → Screen to stream).", "Sanal ekranın var olduğundan ve Sunshine'ın onu kullandığından emin olun (Kontrol → Yayınlanacak ekran)."),
                              m.t("Grant Screen Recording permission to Sunshine, then restart it.", "Sunshine'a Ekran Kaydı izni verin, sonra yeniden başlatın."),
                              m.t("If you recreated the virtual display its ID changed: select it again.", "Sanal ekranı yeniden oluşturduysanız ID'si değişir: yeniden seçin.")],
                      actions: [(m.t("Screen Recording", "Ekran Kaydı"), { m.openScreenRecordingSettings() }),
                                (m.t("Auto-pick display", "Ekranı otomatik seç"), { if let d = m.suggestedDisplay { Task { await m.writeOutput(d.id) } } })]),
            GuideItem(scene: "blurry", title: m.t("Blurry or stretched image", "Bulanık veya gerilmiş görüntü"),
                      steps: [m.t("Set the virtual display to 1920×1200 and the same resolution in Moonlight.", "Sanal ekranı 1920×1200 yapın, Moonlight'ta da aynı çözünürlüğü seçin."),
                              m.t("Keep HiDPI off for a 1:1 match.", "Birebir eşleşme için HiDPI'yi kapalı tutun.")]),
            GuideItem(scene: "lag", title: m.t("Lag or stuttering", "Gecikme veya takılma"),
                      steps: [m.t("Use 5 GHz Wi-Fi on the tablet; connect the Mac with an Ethernet cable if possible.", "Tablette 5 GHz Wi-Fi kullanın; mümkünse Mac'i Ethernet ile bağlayın."),
                              m.t("Moonlight: bitrate 20–40 Mbps, 60 FPS, HEVC on.", "Moonlight: bit hızı 20–40 Mbps, 60 FPS, HEVC açık."),
                              m.t("Move closer to the router and pause heavy downloads.", "Router'a yaklaşın, ağır indirmeleri durdurun.")]),
            GuideItem(scene: "firewall", title: m.t("Firewall blocks the connection", "Güvenlik duvarı bağlantıyı engelliyor"),
                      steps: [m.t("System Settings → Network → Firewall: allow incoming connections for Sunshine.", "Sistem Ayarları → Ağ → Güvenlik Duvarı: Sunshine için gelen bağlantılara izin verin."),
                              m.t("Ports used: TCP 47984, 47989, 47990, 48010 · UDP 47998–48000.", "Kullanılan portlar: TCP 47984, 47989, 47990, 48010 · UDP 47998–48000.")]),
            GuideItem(scene: "logs", title: m.t("Still stuck? Read the log", "Hâlâ olmuyor mu? Günlüğe bakın"),
                      steps: [m.t("The last lines of the Sunshine log usually name the problem.", "Sunshine günlüğünün son satırları genellikle sorunu söyler."),
                              m.t("“Unable to find display” = virtual display missing/permission. “Fatal” lines are the important ones.", "“Unable to find display” = sanal ekran yok/izin eksik. “Fatal” satırları önemlidir.")],
                      actions: [(m.t("Open Sunshine log", "Sunshine günlüğünü aç"), { m.openLogFile() })]),
        ]
    }

    var body: some View {
        HeaderView(symbol: "questionmark.circle.fill", title: m.t("How-to & Help", "Nasıl Yapılır & Yardım"),
                   subtitle: m.t("From zero to a working second screen, and what to do when it fails", "Sıfırdan çalışan ikinci ekrana, ve olmadığında yapılacaklar"), tint: .teal)
        Text(m.t("Quick start", "Hızlı başlangıç")).font(.title3.bold())
        ForEach(quickStart) { GuideCard(item: $0) }
        Text(m.t("Connection failed? Troubleshooting", "Bağlantı başarısız mı? Sorun giderme")).font(.title3.bold()).padding(.top, 8)
        ForEach(trouble) { GuideCard(item: $0) }
    }
}

struct GuideCard: View {
    var item: GuideItem
    var body: some View {
        Card {
            Text(item.title).font(.headline)
            Scenes.make(item.scene)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(item.steps.indices, id: \.self) { i in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•").foregroundStyle(.secondary)
                        Text(item.steps[i]).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            if !item.actions.isEmpty {
                HStack { ForEach(item.actions.indices, id: \.self) { i in Button(item.actions[i].0, action: item.actions[i].1) } }
            }
        }
    }
}

// MARK: - Menu bar
struct MenuContent: View {
    @EnvironmentObject var m: AppModel
    var body: some View {
        Text(m.sunshineRunning ? "● " + m.t("Sunshine running", "Sunshine çalışıyor") : "○ " + m.t("Sunshine stopped", "Sunshine durdu"))
        Divider()
        Button(m.t("Start", "Başlat")) { Task { await m.start() } }.disabled(m.sunshineRunning || !m.sunshineInstalled)
        Button(m.t("Restart", "Yeniden başlat")) { Task { await m.restart() } }.disabled(!m.sunshineInstalled)
        Button(m.t("Stop", "Durdur")) { Task { await m.stop() } }.disabled(!m.sunshineRunning)
        Divider()
        Button(m.t("Open Sunshine web UI", "Sunshine web arayüzünü aç")) { m.openWebUI() }
        Button(m.t("Open TabScreen", "TabScreen'i aç")) { NSApp.activate(ignoringOtherApps: true) }
        Divider()
        Button(m.t("Quit", "Çık")) { NSApp.terminate(nil) }
    }
}

// MARK: - About
enum AppInfo {
    static let authorName = "Yetkin AYDIN"
    static let email = "info@yaydin.com"
    static let website = "https://www.yaydin.com"
    static var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}

struct AboutView: View {
    @EnvironmentObject var m: AppModel

    var body: some View {
        HStack(spacing: 18) {
            Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 84, height: 84)
            VStack(alignment: .leading, spacing: 4) {
                Text("TabScreen").font(.largeTitle.bold())
                Text(m.t("Version", "Sürüm") + " " + AppInfo.version).foregroundStyle(.secondary)
            }
        }

        Card {
            Label(m.t("What is it for?", "Ne işe yarar?"), systemImage: "sparkles").font(.headline)
            Text(m.t(
                "TabScreen turns your Android tablet into a wireless second screen for your Mac. It sets up a virtual display, the Sunshine streaming server and the Moonlight connection for you, and lets you start, stop, restart and auto-start the service from one friendly window or the menu bar. If something goes wrong, the built-in illustrated guide helps you fix it.",
                "TabScreen, Android tabletinizi Mac'iniz için kablosuz ikinci ekrana dönüştürür. Sanal ekranı, Sunshine yayın sunucusunu ve Moonlight bağlantısını sizin için hazırlar; servisi tek bir pencereden ya da menü çubuğundan başlatmanızı, durdurmanızı, yeniden başlatmanızı ve girişte otomatik çalıştırmanızı sağlar. Bir şey ters giderse, içindeki görsel rehber sorunu çözmenize yardım eder."))
                .fixedSize(horizontal: false, vertical: true)
            Text(m.t("It relies on the free, open-source tools Sunshine and Moonlight (and Crisp or BetterDisplay for the virtual display).",
                     "Ücretsiz ve açık kaynaklı Sunshine ve Moonlight araçlarını (sanal ekran için Crisp veya BetterDisplay'i) kullanır."))
                .font(.callout).foregroundStyle(.secondary)
        }

        Card {
            Label(m.t("Author & contact", "Geliştirici ve iletişim"), systemImage: "person.crop.circle.fill").font(.headline)
            HStack { Image(systemName: "person.fill").frame(width: 22); Text(AppInfo.authorName) }
            HStack {
                Image(systemName: "envelope.fill").frame(width: 22)
                Button(AppInfo.email) { m.openURL("mailto:" + AppInfo.email) }.buttonStyle(.link)
            }
            HStack {
                Image(systemName: "globe").frame(width: 22)
                Button(AppInfo.website.replacingOccurrences(of: "https://", with: "")) { m.openURL(AppInfo.website) }.buttonStyle(.link)
            }
        }

        Text("© 2026 " + AppInfo.authorName).font(.caption).foregroundStyle(.secondary)
    }
}
