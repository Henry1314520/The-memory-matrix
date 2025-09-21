import SwiftUI
import AVFoundation

// MARK: - 背景音管理器
class AudioManager: ObservableObject {
    static let shared = AudioManager()
    var player: AVAudioPlayer?
    
    func playBackgroundMusic(loop: Bool = true) {
        guard let url = Bundle.main.url(forResource: "background", withExtension: "mp3") else {
            print("找不到 background.mp3")
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = loop ? -1 : 0
            player?.play()
        } catch {
            print("播放背景音失敗: \(error)")
        }
    }
    
    func stopBackgroundMusic() {
        player?.stop()
    }
    
    func isPlaying() -> Bool {
        return player?.isPlaying ?? false
    }
}

// MARK: - 主畫面
struct ContentView: View {
    @State private var showGame = false
    @State private var soundEnabled = true
    
    // 依螢幕寬度自適應的字體大小
    private var titleFontSize: CGFloat {
        let base = UIScreen.main.bounds.width * 0.12
        return min(base, 100)
    }
    
    private var startButtonFontSize: CGFloat {
        let base = UIScreen.main.bounds.width * 0.06
        return min(base, 34)
    }
    
    var body: some View {
        ZStack {
            // 使用黑色背景，如果有背景图可以替换
            //Color.white.ignoresSafeArea()
            // 如果要使用背景图，取消下面这行的注释并注释上面一行
            Image("Summer5").resizable().scaledToFill().ignoresSafeArea()
            
            if showGame {
                GameView(soundEnabled: $soundEnabled, onExit: {
                    showGame = false
                })
                .onAppear {
                    if soundEnabled && !AudioManager.shared.isPlaying() {
                        AudioManager.shared.playBackgroundMusic()
                    }
                }
            } else {
                VStack {
                    // 顶部音频控制按钮
                    HStack {
                        Spacer()
                        Button(action: {
                            soundEnabled.toggle()
                            if soundEnabled {
                                AudioManager.shared.playBackgroundMusic()
                            } else {
                                AudioManager.shared.stopBackgroundMusic()
                            }
                        }) {
                            Image(systemName: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.pink)
                                .padding(12)
                                .background(Color.white.opacity(0.7))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    
                    Spacer()
                    
                    // 游戏标题
                    Text("記憶方塊")
                        .font(.system(size: 80, weight: .heavy))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .foregroundColor(.white)
                        .padding(.bottom, 350)
                    
                    // 开始游戏按钮
                    Button(action: { showGame = true }) {
                        Text("開始遊戲")
                            .font(.system(size: startButtonFontSize, weight: .bold))
                            .padding(.horizontal, 40)
                            .padding(.vertical, 20)
                            .background(Color.blue.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .shadow(radius: 5)
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

// MARK: - 遊戲畫面
struct GameView: View {
    @Binding var soundEnabled: Bool
    var onExit: () -> Void
    
    @State private var sequence: [Int] = []
    @State private var userSequence: [Int] = []
    @State private var isUserTurn = false
    @State private var flashingIndex: Int? = nil
    @State private var level = 1
    @State private var gameOverAlert = false
    
    let columns = [
        GridItem(.flexible(minimum: 70, maximum: 100), spacing: 8),
        GridItem(.flexible(minimum: 70, maximum: 100), spacing: 8),
        GridItem(.flexible(minimum: 70, maximum: 100), spacing: 8)
    ]
    
    // 自適應的等級字體
    private var levelFontSize: CGFloat {
        let base = UIScreen.main.bounds.width * 0.08
        return min(base, 34)
    }
    
    var body: some View {
        ZStack {
            // 背景
            //Color.black.ignoresSafeArea()
            // 如果要使用背景图，取消下面这行的注释并注释上面一行
             Image("Summer5").resizable().scaledToFill().ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 顶部按钮栏
                HStack {
                    // 返回按钮
                    Button(action: { onExit() }) {
                        Image(systemName: "arrow.backward.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.pink)
                            .padding(12)
                            .background(Color.gray.opacity(0.7))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // 音频控制按钮
                    Button(action: {
                        soundEnabled.toggle()
                        if soundEnabled {
                            AudioManager.shared.playBackgroundMusic()
                        } else {
                            AudioManager.shared.stopBackgroundMusic()
                        }
                    }) {
                        Image(systemName: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.gray.opacity(0.7))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer().frame(height: 40)
                
                // 等级显示
                Text("Level \(level)")
                    .font(.system(size: 60, weight: .bold))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                
                // 游戏网格
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(0..<9, id: \.self) { index in
                        Button(action: {
                            if isUserTurn {
                                userTap(index)
                            }
                        }) {
                            Rectangle()
                                .fill(flashingIndex == index ? Color.yellow : Color.pink
                                )
                                .frame(height: 90)
                                .cornerRadius(12)
                                .shadow(radius: 4)
                        }
                        .disabled(!isUserTurn)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                
                // 重新开始按钮
                Button(action: { resetGame() }) {
                    Text("重新開始")
                        .font(.system(size: UIScreen.main.bounds.width * 0.05, weight: .bold))
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.orange.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                }
                
                Spacer()
            }
        }
        .onAppear {
            if soundEnabled && !AudioManager.shared.isPlaying() {
                AudioManager.shared.playBackgroundMusic()
            }
            startGame()
        }
        .alert(isPresented: $gameOverAlert) {
            Alert(
                title: Text("遊戲結束"),
                message: Text("你在 Level \(level) 失敗了！最終得分: \(level - 1)"),
                dismissButton: .default(Text("再玩一次"), action: {
                    startGame()
                })
            )
        }
    }
    
    // MARK: - 游戏逻辑
    func startGame() {
        sequence = []
        level = 1
        nextRound()
    }
    
    func resetGame() {
        startGame()
    }
    
    func nextRound() {
        userSequence.removeAll()
        isUserTurn = false
        sequence.append(Int.random(in: 0..<9))
        playSequence()
    }
    
    func playSequence() {
        let stepDelay = max(0.3, 1.0 - Double(level) * 0.05) // 最快到 0.3 秒
        for (i, index) in sequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * stepDelay) {
                flash(index)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(sequence.count) * stepDelay) {
            isUserTurn = true
        }
    }

    
    func flash(_ index: Int) {
        flashingIndex = index
        AudioServicesPlaySystemSound(1104) // 按方塊音效
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            flashingIndex = nil
        }
    }
    
    func userTap(_ index: Int) {
        flash(index)
        userSequence.append(index)
        
        // 检查用户输入是否正确
        if userSequence[userSequence.count - 1] != sequence[userSequence.count - 1] {
            gameOverAlert = true
            return
        }
        
        // 如果用户完成了当前序列
        if userSequence.count == sequence.count {
            level += 1
            isUserTurn = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                nextRound()
            }
        }
    }
}

#Preview {
    ContentView()
}
