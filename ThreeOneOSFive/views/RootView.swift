import SwiftUI
import UIKit

enum FFMode: String, CaseIterable, Identifiable {
    case normal = "FF NORMAL"
    case max = "FF MAX"
    
    var id: String { rawValue }
    
    var bundleID: String {
        switch self {
        case .normal: return "com.dts.freefireth"
        case .max: return "com.dts.freefiremax"
        }
    }
    
    var folderName: String {
        switch self {
        case .normal: return "FF NORMAL"
        case .max: return "FF MAX"
        }
    }
    
    var displayName: String {
        switch self {
        case .normal: return "FREE FIRE TH"
        case .max: return "FREE FIRE MAX"
        }
    }
}

@MainActor
final class AppSession: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var selectedMode: FFMode? = nil
    
    func logout() {
        isAuthenticated = false
        selectedMode = nil
    }
}

struct RootView: View {
    @StateObject private var session = AppSession()
    @StateObject private var supabase = SupabaseService()
    @State private var showSplash = true
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        ZStack {
            // 1️⃣ Splash
            if showSplash {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
                .zIndex(2)
            }
            // 2️⃣ 🚧 Modo mantenimiento
            else if supabase.isMaintenanceMode {
                MaintenanceView(message: supabase.maintenanceMessage)
                    .transition(.opacity)
                    .zIndex(4)
            }
            // 3️⃣ ❄️ Key congelada
            else if supabase.isKeyFrozen {
                FrozenKeyView()
                    .transition(.opacity)
                    .zIndex(3)
            }
            // 4️⃣ 🚫 Acceso revocado (ban/expira/delete)
            else if supabase.isKeyRevoked {
                RevokedAccessView()
                    .transition(.opacity)
                    .zIndex(3)
            }
            // 5️⃣ Flujo normal
            else {
                if !session.isAuthenticated {
                    LoginView(session: session)
                        .environmentObject(supabase)
                        .transition(.opacity)
                } else if session.selectedMode == nil {
                    ModeSelectionView(session: session)
                        .environmentObject(supabase)
                        .transition(.opacity)
                } else {
                    ControlPanelView(session: session)
                        .environmentObject(supabase)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: session.isAuthenticated)
        .animation(.easeInOut(duration: 0.25), value: session.selectedMode)
        .animation(.easeInOut(duration: 0.25), value: supabase.isKeyRevoked)
        .animation(.easeInOut(duration: 0.25), value: supabase.isKeyFrozen)
        .animation(.easeInOut(duration: 0.25), value: supabase.isMaintenanceMode)
        .animation(.easeInOut(duration: 0.4), value: showSplash)
        .onAppear {
            supabase.subscribeToMaintenance()
            Task {
                await supabase.checkMaintenanceStatus()
            }
            
            // Escuchar el botón "Reintentar" de la pantalla de congelado
            NotificationCenter.default.addObserver(
                forName: .frozenKeyRetry,
                object: nil,
                queue: .main
            ) { _ in
                Task {
                    if let key = supabase.currentKey {
                        await revalidateKey(key.keyValue)
                    }
                }
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                Task {
                    await supabase.checkMaintenanceStatus()
                }
                // Revalidar key al volver del background
                if session.isAuthenticated, let key = supabase.currentKey {
                    Task {
                        await revalidateKey(key.keyValue)
                    }
                }
            }
        }
    }
    
    private func revalidateKey(_ keyValue: String) async {
        do {
            _ = try await supabase.verifyKey(keyValue)
            log("root: key revalidated OK")
            // Si la key es válida, quitar los estados de revocado/congelado
            await MainActor.run {
                supabase.isKeyFrozen = false
                supabase.isKeyRevoked = false
            }
        } catch let error as SupabaseError {
            log("root: key revalidation failed — \(error)")
            await MainActor.run {
                switch error {
                case .keyBanned, .keyExpired, .keyNotFound:
                    supabase.isKeyRevoked = true
                    supabase.isKeyFrozen = false
                case .keyInactive:
                    supabase.isKeyFrozen = true
                    supabase.isKeyRevoked = false
                default:
                    break
                }
            }
        } catch {
            log("root: key revalidation error — \(error)")
        }
    }
}
