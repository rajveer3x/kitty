import SwiftUI

struct CatStatusItem: View {
    @ObservedObject var cpuMonitor: CPUMonitor

    var body: some View {
        TimelineView(.periodic(from: .now, by: frameInterval)) { context in
            let motion = motion(at: context.date)
            ChibiCat(phase: motion.phase, isMoving: motion.isMoving, isRunning: motion.isRunning, isResting: motion.isResting)
                // TimelineView supplies only 4 / 8 keyframes per second;
                // SwiftUI interpolates the lightweight vector between them.
                .animation(animation(for: motion), value: motion.frame)
                .transaction { transaction in
                    if !cpuMonitor.shouldAnimate { transaction.animation = nil }
                }
                .frame(width: 34, height: 22)
                .accessibilityLabel("Kitty, CPU \(Int(cpuMonitor.usagePercent)) percent")
        }
    }

    private var frameInterval: TimeInterval {
        guard cpuMonitor.shouldAnimate else { return 60 }
        return cpuMonitor.gait == .walking ? 0.25 : 0.125
    }

    private func animation(for motion: CatMotion) -> Animation? {
        guard cpuMonitor.shouldAnimate else { return nil }
        if motion.isRunning {
            // The spring slightly overshoots each running keyframe, giving the
            // tail a soft elastic recoil while keeping the update rate at 8 FPS.
            return .spring(response: 0.18, dampingFraction: 0.68)
        }
        return .linear(duration: frameInterval * 0.92)
    }

    private func motion(at date: Date) -> CatMotion {
        guard cpuMonitor.shouldAnimate else { return .rest }
        let framesPerSecond = cpuMonitor.gait == .walking ? 4.0 : 8.0
        let frame = Int(date.timeIntervalSinceReferenceDate * framesPerSecond)
        // A one-second walk cycle feels lively at 4 keyframes/sec; running
        // keeps the same keyframe count but advances twice as fast.
        let phaseStep: CGFloat = 0.25
        return CatMotion(frame: frame, phase: CGFloat(frame) * phaseStep, isMoving: true, isRunning: cpuMonitor.gait == .running, isResting: false)
    }
}

private struct CatMotion: Equatable {
    let frame: Int
    let phase: CGFloat
    let isMoving: Bool
    let isRunning: Bool
    let isResting: Bool

    static let rest = CatMotion(frame: 0, phase: 0, isMoving: false, isRunning: false, isResting: true)
}

/// A deliberately stylized chibi cat: soft curves and pendulum legs keep the
/// sprite readable at menu-bar size and make it easy to replace with PNG frames.
struct ChibiCat: View, Animatable {
    var phase: CGFloat
    let isMoving: Bool
    let isRunning: Bool
    let isResting: Bool

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    private let fur = Color(red: 0.98, green: 0.62, blue: 0.30)
    private let belly = Color(red: 1.0, green: 0.80, blue: 0.56)
    private let eye = Color(red: 0.12, green: 0.08, blue: 0.10)

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 34, size.height / 22)
            context.scaleBy(x: scale, y: scale)

            if isResting {
                drawSleepingCat(context: &context)
                return
            }

            let cycle = phase - floor(phase)
            let wave = sin(cycle * .pi * 2)
            let energy = abs(wave)
            let bob = isRunning ? energy * 0.65 : energy * 0.35
            let squash = isRunning ? energy * 0.75 : 0
            let bodyWidth = 15.0 + squash * 2.0
            let bodyHeight = 7.0 - squash * 0.75
            let bodyX = 7.3 - squash * 0.45
            let bodyY = 11.0 + bob + squash * 0.18
            let stride: CGFloat = isRunning ? 2.0 : 0.85

            drawTail(context: &context, cycle: cycle, running: isRunning, baseY: bodyY + 2.0)

            // Back legs are slightly lighter and sit behind the round torso.
            drawStubLeg(context: &context, x: bodyX + 4.0, hipY: bodyY + bodyHeight - 0.8, phase: cycle + 0.50, stride: stride * 0.8, running: isRunning, color: fur.opacity(0.72))
            drawStubLeg(context: &context, x: bodyX + bodyWidth - 3.0, hipY: bodyY + bodyHeight - 0.8, phase: cycle + 0.25, stride: stride * 0.72, running: isRunning, color: fur.opacity(0.72))

            // Round chibi torso with a small warm belly patch.
            context.fill(Path(roundedRect: CGRect(x: bodyX, y: bodyY, width: bodyWidth, height: bodyHeight), cornerRadius: 3.3), with: .color(fur))
            context.fill(Path(ellipseIn: CGRect(x: bodyX + 5.0, y: bodyY + 2.0, width: 6.0, height: 4.0)), with: .color(belly.opacity(0.72)))

            // Short front legs and tiny paws.
            drawStubLeg(context: &context, x: bodyX + 6.3, hipY: bodyY + bodyHeight - 0.4, phase: cycle, stride: stride, running: isRunning, color: fur)
            drawStubLeg(context: &context, x: bodyX + bodyWidth - 2.2, hipY: bodyY + bodyHeight - 0.5, phase: cycle + 0.75, stride: stride * 0.82, running: isRunning, color: fur)

            let headX = isRunning ? 19.2 : 18.8
            let headY = 4.0 + bob - squash * 0.12
            let headWidth = isRunning ? 10.0 : 10.5
            let headHeight = isRunning ? 9.0 : 9.5

            // The tips sit clearly above the oversized head at menu-bar scale.
            drawEar(context: &context, x: headX + 1.2, y: headY - 0.9, scale: 1.05)
            drawEar(context: &context, x: headX + 6.4, y: headY - 0.6, scale: 0.90)
            context.fill(Path(ellipseIn: CGRect(x: headX, y: headY, width: headWidth, height: headHeight)), with: .color(fur))

            // Oversized expressive eyes, a tiny nose, and a soft cheek highlight.
            let eyeY = headY + 3.0
            drawEye(context: &context, center: CGPoint(x: headX + 3.7, y: eyeY))
            drawEye(context: &context, center: CGPoint(x: headX + 7.2, y: eyeY + 0.1))
            context.fill(Path(ellipseIn: CGRect(x: headX + 9.0, y: headY + 5.0, width: 0.8, height: 0.65)), with: .color(Color(red: 0.55, green: 0.12, blue: 0.10)))
            context.fill(Path(ellipseIn: CGRect(x: headX + 1.1, y: headY + 6.2, width: 1.5, height: 0.8)), with: .color(Color.white.opacity(0.26)))
        }
    }

    private func drawEye(context: inout GraphicsContext, center: CGPoint) {
        context.fill(Path(ellipseIn: CGRect(x: center.x - 1.0, y: center.y - 1.35, width: 2.0, height: 2.7)), with: .color(eye))
        context.fill(Path(ellipseIn: CGRect(x: center.x - 0.48, y: center.y - 0.92, width: 0.62, height: 0.72)), with: .color(.white))
    }

    private func drawEar(context: inout GraphicsContext, x: CGFloat, y: CGFloat, scale: CGFloat) {
        var ear = Path()
        ear.move(to: CGPoint(x: x - 1.2 * scale, y: y + 4.2 * scale))
        ear.addCurve(to: CGPoint(x: x, y: y - 0.8 * scale), control1: CGPoint(x: x - 0.9 * scale, y: y + 1.0 * scale), control2: CGPoint(x: x - 0.35 * scale, y: y - 0.7 * scale))
        ear.addCurve(to: CGPoint(x: x + 1.6 * scale, y: y + 4.1 * scale), control1: CGPoint(x: x + 0.8 * scale, y: y - 0.1 * scale), control2: CGPoint(x: x + 1.35 * scale, y: y + 1.5 * scale))
        ear.closeSubpath()
        context.fill(ear, with: .color(fur))
    }

    private func drawStubLeg(context: inout GraphicsContext, x: CGFloat, hipY: CGFloat, phase: CGFloat, stride: CGFloat, running: Bool, color: Color) {
        let swing = sin(phase * .pi * 2) * stride
        let lift = running ? max(0, sin((phase + 0.18) * .pi * 2)) * 2.15 : max(0, sin((phase + 0.1) * .pi * 2)) * 0.45
        let paw = CGPoint(x: x + swing, y: 20.8 - lift)
        let knee = CGPoint(x: x + swing * 0.35, y: hipY + 1.0 - lift * 0.45)
        var leg = Path()
        leg.move(to: CGPoint(x: x, y: hipY))
        leg.addCurve(to: knee, control1: CGPoint(x: x + swing * 0.1, y: hipY + 0.8), control2: CGPoint(x: knee.x - swing * 0.15, y: knee.y - 0.2))
        leg.addCurve(to: paw, control1: CGPoint(x: knee.x + swing * 0.25, y: knee.y + 0.8), control2: CGPoint(x: paw.x - swing * 0.15, y: paw.y - 1.0))
        leg.addLine(to: CGPoint(x: paw.x + 1.0, y: paw.y))
        context.stroke(leg, with: .color(color), style: StrokeStyle(lineWidth: running ? 2.0 : 2.25, lineCap: .round, lineJoin: .round))
    }

    private func drawTail(context: inout GraphicsContext, cycle: CGFloat, running: Bool, baseY: CGFloat) {
        let sway = sin(cycle * .pi * 2)
        var tail = Path()
        tail.move(to: CGPoint(x: 8.0, y: baseY))
        if running {
            // The base follows the body cadence directly. The tip samples a
            // delayed phase, creating spring-like follow-through down the S.
            let cadence = cycle * .pi * 2
            let baseWobble = sin(cadence) * 0.55
            let delayed = (cycle - 0.13) * .pi * 2
            let tipFollowThrough = sin(delayed) * 1.25
            let midFollowThrough = sin((cycle - 0.06) * .pi * 2) * 0.72

            tail.addCurve(
                to: CGPoint(x: 4.9, y: 11.4 + midFollowThrough * 0.55),
                control1: CGPoint(x: 6.8, y: 13.0 + baseWobble * 0.6),
                control2: CGPoint(x: 5.7, y: 10.8 + baseWobble * 0.35)
            )
            tail.addCurve(
                to: CGPoint(x: 2.1, y: 11.8 + tipFollowThrough * 0.45),
                control1: CGPoint(x: 4.0, y: 11.0 + midFollowThrough * 0.55),
                control2: CGPoint(x: 3.0, y: 12.8 + tipFollowThrough * 0.35)
            )
            tail.addCurve(
                to: CGPoint(x: 0.35, y: 9.9 + tipFollowThrough),
                control1: CGPoint(x: 1.45, y: 11.1 + tipFollowThrough * 0.5),
                control2: CGPoint(x: 0.72, y: 10.55 + tipFollowThrough * 0.9)
            )
        } else {
            // A slow, friendly upright curve while walking.
            tail.addCurve(to: CGPoint(x: 3.3, y: 6.0), control1: CGPoint(x: 4.0 + sway * 0.35, y: 12.8), control2: CGPoint(x: 2.0 + sway * 0.35, y: 8.6))
            tail.addCurve(to: CGPoint(x: 4.2 + sway * 0.45, y: 1.0), control1: CGPoint(x: 5.2 + sway * 0.25, y: 4.0), control2: CGPoint(x: 3.6 + sway * 0.45, y: 2.2))
        }
        context.stroke(tail, with: .color(fur), style: StrokeStyle(lineWidth: running ? 2.0 : 2.25, lineCap: .round, lineJoin: .round))
    }

    private func drawSleepingCat(context: inout GraphicsContext) {
        var tail = Path()
        tail.move(to: CGPoint(x: 13.0, y: 17.4))
        tail.addCurve(to: CGPoint(x: 5.9, y: 19.0), control1: CGPoint(x: 9.0, y: 20.2), control2: CGPoint(x: 5.4, y: 20.2))
        tail.addCurve(to: CGPoint(x: 8.4, y: 16.0), control1: CGPoint(x: 5.6, y: 17.5), control2: CGPoint(x: 7.2, y: 15.2))
        context.stroke(tail, with: .color(fur), style: StrokeStyle(lineWidth: 2.1, lineCap: .round, lineJoin: .round))

        context.fill(Path(ellipseIn: CGRect(x: 9.0, y: 11.8, width: 12.0, height: 7.7)), with: .color(fur))
        context.fill(Path(ellipseIn: CGRect(x: 17.5, y: 6.8, width: 7.0, height: 6.8)), with: .color(fur))
        drawEar(context: &context, x: 19.0, y: 5.2, scale: 0.85)
        drawEar(context: &context, x: 22.0, y: 5.4, scale: 0.72)

        var closedEye = Path()
        closedEye.move(to: CGPoint(x: 19.5, y: 10.0))
        closedEye.addCurve(to: CGPoint(x: 20.9, y: 10.0), control1: CGPoint(x: 19.8, y: 10.4), control2: CGPoint(x: 20.6, y: 10.4))
        context.stroke(closedEye, with: .color(eye), style: StrokeStyle(lineWidth: 0.65, lineCap: .round))
    }
}
