import SwiftUI

struct ContentView: View {
    @EnvironmentObject var acoustic: AcousticTelemetryEngineWrapper
@EnvironmentObject var speech: SpeechTelemetryEngineWrapper
@EnvironmentObject var friction: FrictionCoachEngineWrapper
    
    var body: some View {
        VStack(spacing: 20) {
            Text("ExecCommuteCoach")
                .font(.title2).bold()
            HStack {
                Text("Fundamental Frequency:")
                Spacer()
                Text(String(format: "%.1f Hz", acoustic.frequency))
                    .foregroundColor(.blue)
            }
            HStack {
                Text("Words‑per‑minute:")
                Spacer()
                Text("\(speech.wpm)")
                    .foregroundColor(.green)
            }
            if !speech.lastFiller.isEmpty {
                HStack {
                    Text("Last filler detected:")
                    Spacer()
                    Text(speech.lastFiller)
                        .foregroundColor(.orange)
                }
            }
            if !friction.lastPrompt.isEmpty {
                HStack {
                    Text("Coach Prompt:")
                    Spacer()
                    Text(friction.lastPrompt)
                        .foregroundColor(.red)
                }
            }
            Spacer()
        }
        .padding()
        .onAppear {
            // engines already started in wrappers' init
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AcousticTelemetryEngineWrapper())
            .environmentObject(SpeechTelemetryEngineWrapper())
            .environmentObject(FrictionCoachEngineWrapper())
    }
}
