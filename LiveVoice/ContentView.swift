import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    // Wave animation states
    @State private var waveAnimation = false
    
    var body: some View {
        ZStack {
            // Arka plan
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Üst Başlık
                Text("LiveVoice")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 40)
                
                Spacer()
                
                // Ses Dalgaları (Siri Tarzı Görselleştirme)
                ZStack {
                    ForEach(0..<5) { index in
                        Circle()
                            .stroke(lineWidth: viewModel.isListening ? 4 : 1)
                            .frame(width: 100 + CGFloat(index * 30), height: 100 + CGFloat(index * 30))
                            .foregroundColor(viewModel.isListening ? .blue.opacity(0.5) : .gray.opacity(0.2))
                            .scaleEffect(waveAnimation && viewModel.isListening ? 1.5 : 1.0)
                            .opacity(waveAnimation && viewModel.isListening ? 0.0 : 1.0)
                            .animation(
                                .easeOut(duration: 1.5)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.2),
                                value: waveAnimation
                            )
                    }
                    
                    // Dinleme Butonu
                    Button(action: {
                        viewModel.toggleListening()
                    }) {
                        Image(systemName: viewModel.isListening ? "mic.fill" : "mic.slash.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .frame(width: 80, height: 80)
                            .background(viewModel.isListening ? Color.blue : Color.gray)
                            .clipShape(Circle())
                            .shadow(color: viewModel.isListening ? .blue : .clear, radius: 10)
                    }
                }
                .onAppear {
                    waveAnimation = true
                }
                
                Spacer()
                
                // Altyazı Kutusu (Gerçek Zamanlı Çeviri)
                VStack(spacing: 15) {
                    // Kaynak Metin (Orijinal)
                    if !viewModel.sourceText.isEmpty {
                        Text(viewModel.sourceText)
                            .font(.system(size: 18, weight: .regular, design: .default))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }
                    
                    // Çeviri Metni
                    Text(viewModel.translatedText.isEmpty ? "Konuşmak için mikrofona dokunun..." : viewModel.translatedText)
                        .font(.system(size: 24, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(15)
                        .animation(.easeInOut, value: viewModel.translatedText)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(MainViewModel())
    }
}
