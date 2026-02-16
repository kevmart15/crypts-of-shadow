// CRYPTS OF SHADOW — Dead Cells-Inspired Roguelike Dungeon Crawler
// Native macOS • SpriteKit • Programmatic Pixel Art

import AppKit
import SpriteKit

// ══════════════════════════════════════════════════════════════
// MARK: - CONFIG
// ══════════════════════════════════════════════════════════════
let WIN_W: CGFloat = 1200
let WIN_H: CGFloat = 800
let S: CGFloat = 3                  // pixel scale
let TS: CGFloat = 48                // tile size in screen pts (16*3)
let GRAVITY: CGFloat = -1500
let JUMP_VEL: CGFloat = 920
let MOVE_SPD: CGFloat = 280
let MAX_FALL: CGFloat = -1000
let ROLL_SPD: CGFloat = 650
let ROLL_DUR: CGFloat = 0.3
let WALL_SLIDE: CGFloat = -80
let WALL_JUMP_H: CGFloat = 500
let WALL_JUMP_V: CGFloat = 680
let COYOTE: CGFloat = 0.08
let JUMP_BUF: CGFloat = 0.08
let ATTACK_DUR: CGFloat = 0.35
let ATTACK_REACH: CGFloat = 70
let INV_TIME: CGFloat = 1.2
let LEVEL_COLS = 80
let LEVEL_ROWS = 25

// ══════════════════════════════════════════════════════════════
// MARK: - COLORS
// ══════════════════════════════════════════════════════════════
func rgb(_ r: Int, _ g: Int, _ b: Int) -> NSColor {
    NSColor(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: 1)
}
let OL = rgb(10, 8, 18)          // outline
let C1 = rgb(35, 28, 58)         // cloak dark
let C2 = rgb(55, 45, 82)         // cloak mid
let C3 = rgb(75, 60, 108)        // cloak light
let A1 = rgb(55, 55, 68)         // armor dark
let A2 = rgb(80, 80, 95)         // armor mid
let A3 = rgb(108, 108, 122)      // armor light
let SK = rgb(180, 140, 108)      // skin
let SD = rgb(140, 105, 78)       // skin dark
let EG = rgb(80, 255, 140)       // eye glow
let BD = rgb(55, 40, 30)         // boot dark
let BM = rgb(80, 60, 45)         // boot mid
let GD = rgb(180, 140, 50)       // gold
let SW = rgb(150, 150, 165)      // sword
let SE = rgb(220, 220, 240)      // sword edge
let ZF = rgb(78, 105, 68)        // zombie flesh
let ZD = rgb(50, 72, 45)         // zombie dark
let BN = rgb(205, 195, 178)      // bone
let BO = rgb(155, 145, 130)      // bone dark
let BG_COL = rgb(10, 8, 18)      // scene bg

// ══════════════════════════════════════════════════════════════
// MARK: - SPRITE HELPERS
// ══════════════════════════════════════════════════════════════
func sprite(_ w: Int, _ h: Int, _ draw: (CGContext) -> Void) -> SKTexture {
    let img = NSImage(size: NSSize(width: w, height: h))
    img.lockFocus()
    let ctx = NSGraphicsContext.current!.cgContext
    draw(ctx)
    img.unlockFocus()
    let t = SKTexture(image: img)
    t.filteringMode = .nearest
    return t
}
func f(_ c: CGContext, _ x: Int, _ y: Int, _ w: Int, _ h: Int, _ col: NSColor) {
    c.setFillColor(col.cgColor); c.fill(CGRect(x: x, y: y, width: w, height: h))
}
func px(_ c: CGContext, _ x: Int, _ y: Int, _ col: NSColor) { f(c, x, y, 1, 1, col) }

// ══════════════════════════════════════════════════════════════
// MARK: - TILE TYPES
// ══════════════════════════════════════════════════════════════
enum Tile: Int { case empty = 0, wall, floor, platform, bgWall, door }

struct EnemySpawn { var x: CGFloat; var y: CGFloat; var type: Int }
struct TorchInfo { var x: CGFloat; var y: CGFloat }

// ══════════════════════════════════════════════════════════════
// MARK: - TEXTURE FACTORY
// ══════════════════════════════════════════════════════════════
class Tex {
    static let shared = Tex()

    // Player base drawing (shared across frames)
    private func playerBase(_ c: CGContext, ox: Int, legL: Int, legR: Int) {
        // Hood
        f(c, 5+ox, 17, 6, 5, C1); f(c, 6+ox, 18, 4, 3, C2); f(c, 7+ox, 19, 2, 2, C3)
        // Face + eyes
        f(c, 6+ox, 15, 4, 2, SD); px(c, 7+ox, 16, EG); px(c, 9+ox, 16, EG)
        // Neck
        f(c, 7+ox, 14, 2, 1, SD)
        // Armor
        f(c, 4+ox, 6, 8, 8, A1); f(c, 5+ox, 7, 6, 6, A2); f(c, 6+ox, 8, 4, 4, A3)
        // Belt
        f(c, 5+ox, 10, 6, 1, GD)
        // Cloak sides
        f(c, 3+ox, 8, 1, 5, C1); f(c, 12+ox, 8, 1, 5, C1)
        // Left leg
        f(c, 5+legL+ox, 1, 2, 5, C1); f(c, 5+legL+ox, 2, 2, 3, C2)
        f(c, 4+legL+ox, 0, 3, 2, BD); f(c, 5+legL+ox, 0, 2, 1, BM)
        // Right leg
        f(c, 9+legR+ox, 1, 2, 5, C1); f(c, 9+legR+ox, 2, 2, 3, C2)
        f(c, 8+legR+ox, 0, 3, 2, BD); f(c, 9+legR+ox, 0, 2, 1, BM)
    }

    private func makePlayer(legL: Int, legR: Int, sword: Int) -> SKTexture {
        let wide = sword >= 0
        let w = wide ? 24 : 16
        let ox = wide ? 2 : 0
        return sprite(w, 22) { c in
            // Outline
            f(c, 4+ox, 15, 8, 7, OL); f(c, 3+ox, 5, 10, 11, OL)
            f(c, 3+legL+ox, 0, 5, 6, OL); f(c, 7+legR+ox, 0, 5, 6, OL)
            if sword >= 0 {
                if sword == 0 { f(c, 0, 10, 3, 9, OL) }
                else if sword == 1 { f(c, 13+ox, 10, 10, 3, OL) }
                else { f(c, 13+ox, 4, 8, 3, OL) }
            }
            playerBase(c, ox: ox, legL: legL, legR: legR)
            // Sword
            if sword == 0 { f(c, 1, 11, 1, 7, SW); px(c, 1, 17, SE) }
            else if sword == 1 { f(c, 14+ox, 11, 8, 1, SW); px(c, 21+ox, 11, SE) }
            else if sword == 2 { f(c, 14+ox, 5, 6, 1, SW); px(c, 19+ox, 5, SE) }
        }
    }

    lazy var playerIdle: [SKTexture] = [makePlayer(legL: 0, legR: 0, sword: -1)]
    lazy var playerRun: [SKTexture] = [
        makePlayer(legL: -2, legR: 2, sword: -1),
        makePlayer(legL: -1, legR: 1, sword: -1),
        makePlayer(legL: 2, legR: -2, sword: -1),
        makePlayer(legL: -1, legR: 1, sword: -1),
    ]
    lazy var playerAttack: [SKTexture] = [
        makePlayer(legL: 0, legR: 0, sword: 0),
        makePlayer(legL: 0, legR: 0, sword: 1),
        makePlayer(legL: 0, legR: 0, sword: 2),
    ]
    lazy var playerJump: SKTexture = {
        sprite(16, 22) { c in
            f(c, 4, 15, 8, 7, OL); f(c, 3, 5, 10, 11, OL)
            f(c, 2, 2, 5, 5, OL); f(c, 9, 0, 5, 4, OL)
            self.playerBase(c, ox: 0, legL: -2, legR: 1)
        }
    }()
    lazy var playerFall: SKTexture = {
        sprite(16, 22) { c in
            f(c, 4, 15, 8, 7, OL); f(c, 3, 5, 10, 11, OL)
            f(c, 2, 0, 5, 5, OL); f(c, 8, 0, 5, 5, OL)
            self.playerBase(c, ox: 0, legL: -1, legR: 1)
        }
    }()
    lazy var playerRoll: SKTexture = {
        sprite(18, 14) { c in
            f(c, 2, 3, 14, 9, OL)
            f(c, 3, 4, 12, 7, C1); f(c, 4, 5, 10, 5, C2)
            f(c, 5, 6, 8, 3, A1); f(c, 6, 7, 6, 1, A2)
            px(c, 13, 8, EG); px(c, 14, 8, EG)
        }
    }()

    // ── Zombie ──
    private func makeZombie(legL: Int, legR: Int, arm: Bool) -> SKTexture {
        sprite(14, 20) { c in
            f(c, 3, 13, 8, 6, OL); f(c, 2, 3, 10, 11, OL)
            f(c, 2+legL, 0, 5, 4, OL); f(c, 7+legR, 0, 5, 4, OL)
            // Head
            f(c, 4, 14, 6, 4, ZF); f(c, 5, 15, 4, 2, ZD)
            px(c, 5, 16, rgb(200,30,30)); px(c, 8, 16, rgb(200,30,30))
            f(c, 6, 14, 2, 1, rgb(60,40,35)) // jaw
            // Body
            f(c, 3, 5, 8, 8, ZD); f(c, 4, 6, 6, 6, ZF)
            f(c, 5, 7, 4, 4, rgb(65,88,58)) // highlight
            // Torn shirt
            f(c, 4, 10, 2, 1, rgb(80,75,65)); f(c, 8, 9, 2, 1, rgb(80,75,65))
            // Arms
            f(c, 1, 7, 2, 5, ZF); f(c, 11, 7, 2, 5, ZF)
            if arm { f(c, 12, 8, 2, 3, ZF) } // extended arm for attack
            // Legs
            f(c, 3+legL, 1, 3, 4, ZD); f(c, 4+legL, 1, 2, 3, ZF)
            f(c, 8+legR, 1, 3, 4, ZD); f(c, 9+legR, 1, 2, 3, ZF)
            f(c, 3+legL, 0, 3, 1, rgb(50,40,35)); f(c, 8+legR, 0, 3, 1, rgb(50,40,35))
        }
    }
    lazy var zombieWalk: [SKTexture] = [
        makeZombie(legL: -1, legR: 1, arm: false),
        makeZombie(legL: 1, legR: -1, arm: false),
    ]
    lazy var zombieAttack: SKTexture = makeZombie(legL: 0, legR: 0, arm: true)

    // ── Skeleton ──
    private func makeSkeleton(legL: Int, legR: Int, sword: Bool) -> SKTexture {
        sprite(sword ? 20 : 14, 22) { c in
            let ox = sword ? 2 : 0
            // Outline
            f(c, 3+ox, 17, 6, 5, OL); f(c, 3+ox, 8, 8, 9, OL)
            f(c, 3+legL+ox, 0, 3, 9, OL); f(c, 8+legR+ox, 0, 3, 9, OL)
            // Skull
            f(c, 4+ox, 18, 4, 3, BN); f(c, 5+ox, 19, 2, 1, BO)
            px(c, 5+ox, 19, OL); px(c, 7+ox, 19, OL) // eye sockets
            f(c, 5+ox, 17, 2, 1, BO) // jaw
            // Neck
            f(c, 6+ox, 16, 1, 1, BO)
            // Ribcage
            f(c, 4+ox, 10, 6, 6, BN); f(c, 5+ox, 11, 4, 4, BO)
            px(c, 5+ox, 14, OL); px(c, 8+ox, 14, OL) // rib gaps
            px(c, 5+ox, 12, OL); px(c, 8+ox, 12, OL)
            // Spine
            f(c, 6+ox, 8, 1, 2, BO)
            // Arms
            f(c, 2+ox, 12, 1, 4, BN); f(c, 10+ox, 12, 1, 4, BN)
            if sword {
                f(c, 11+ox, 13, 7, 1, SW); px(c, 17+ox, 13, SE)
                f(c, 11+ox, 14, 7, 1, SW); px(c, 17+ox, 14, SE)
            }
            // Pelvis
            f(c, 5+ox, 7, 3, 2, BO)
            // Legs
            f(c, 4+legL+ox, 2, 2, 6, BN); f(c, 4+legL+ox, 2, 1, 5, BO)
            f(c, 9+legR+ox, 2, 2, 6, BN); f(c, 9+legR+ox, 2, 1, 5, BO)
            f(c, 4+legL+ox, 0, 2, 2, BO); f(c, 9+legR+ox, 0, 2, 2, BO)
        }
    }
    lazy var skeletonWalk: [SKTexture] = [
        makeSkeleton(legL: -1, legR: 1, sword: false),
        makeSkeleton(legL: 1, legR: -1, sword: false),
    ]
    lazy var skeletonAttack: SKTexture = makeSkeleton(legL: 0, legR: 0, sword: true)

    // ── Bat ──
    lazy var batFly: [SKTexture] = [
        sprite(16, 12) { c in
            f(c, 6, 3, 4, 5, rgb(40,20,50)); f(c, 7, 4, 2, 3, rgb(60,30,70))
            px(c, 7, 6, rgb(220,30,30)); px(c, 8, 6, rgb(220,30,30))
            px(c, 7, 8, rgb(50,25,60)); px(c, 8, 8, rgb(50,25,60)) // ears
            f(c, 0, 5, 6, 4, rgb(45,22,55)); f(c, 10, 5, 6, 4, rgb(45,22,55))
            f(c, 1, 6, 4, 2, rgb(65,32,75)); f(c, 11, 6, 4, 2, rgb(65,32,75))
        },
        sprite(16, 12) { c in
            f(c, 6, 3, 4, 5, rgb(40,20,50)); f(c, 7, 4, 2, 3, rgb(60,30,70))
            px(c, 7, 6, rgb(220,30,30)); px(c, 8, 6, rgb(220,30,30))
            px(c, 7, 8, rgb(50,25,60)); px(c, 8, 8, rgb(50,25,60))
            f(c, 0, 1, 6, 4, rgb(45,22,55)); f(c, 10, 1, 6, 4, rgb(45,22,55))
            f(c, 1, 2, 4, 2, rgb(65,32,75)); f(c, 11, 2, 4, 2, rgb(65,32,75))
        },
    ]

    // ── Tiles ──
    lazy var wallTex: SKTexture = sprite(16, 16) { c in
        f(c, 0, 0, 16, 16, rgb(48,42,58)); f(c, 1, 1, 14, 14, rgb(56,50,66))
        f(c, 0, 7, 16, 1, rgb(35,30,45)); f(c, 7, 0, 1, 7, rgb(35,30,45))
        f(c, 0, 8, 1, 8, rgb(35,30,45)); f(c, 12, 8, 1, 8, rgb(35,30,45))
        px(c, 3, 3, rgb(65,58,78)); px(c, 10, 12, rgb(65,58,78))
        px(c, 5, 14, rgb(65,58,78)); px(c, 13, 5, rgb(42,36,52)); px(c, 2, 10, rgb(42,36,52))
    }
    lazy var floorTex: SKTexture = sprite(16, 16) { c in
        f(c, 0, 0, 16, 16, rgb(48,42,58))
        f(c, 0, 14, 16, 2, rgb(78,70,90)); f(c, 0, 12, 16, 2, rgb(62,55,72))
        f(c, 0, 5, 16, 1, rgb(35,30,45)); f(c, 4, 0, 1, 5, rgb(35,30,45))
        f(c, 11, 6, 1, 6, rgb(35,30,45))
        px(c, 8, 3, rgb(58,52,68)); px(c, 2, 8, rgb(58,52,68)); px(c, 14, 1, rgb(42,36,52))
    }
    lazy var platformTex: SKTexture = sprite(16, 16) { c in
        f(c, 0, 12, 16, 4, rgb(52,46,62)); f(c, 0, 14, 16, 2, rgb(68,60,80))
        f(c, 0, 15, 16, 1, rgb(82,74,95))
        px(c, 4, 13, rgb(60,54,72)); px(c, 11, 13, rgb(60,54,72))
    }
    lazy var bgWallTex: SKTexture = sprite(16, 16) { c in
        f(c, 0, 0, 16, 16, rgb(18,15,28)); f(c, 2, 2, 12, 12, rgb(22,18,32))
        f(c, 0, 7, 16, 1, rgb(14,11,22)); f(c, 7, 0, 1, 16, rgb(14,11,22))
    }
    lazy var doorTex: SKTexture = sprite(16, 32) { c in
        f(c, 1, 0, 14, 30, rgb(60,42,28)); f(c, 2, 1, 12, 28, rgb(48,32,20))
        f(c, 3, 2, 10, 26, rgb(55,40,25))
        f(c, 3, 26, 10, 3, rgb(65,48,32)) // arch
        f(c, 4, 3, 8, 22, rgb(85,75,55)) // light behind
        f(c, 5, 4, 6, 20, rgb(105,95,65))
        px(c, 11, 14, rgb(200,180,50)); px(c, 11, 13, rgb(200,180,50)) // handle
    }
    lazy var torchFrames: [SKTexture] = [
        sprite(6, 14) { c in
            f(c, 2, 0, 2, 7, rgb(100,70,42)); f(c, 2, 6, 2, 1, rgb(120,88,52))
            f(c, 1, 7, 4, 5, rgb(255,155,50)); f(c, 2, 8, 2, 4, rgb(255,218,95))
            px(c, 2, 11, rgb(255,240,150))
        },
        sprite(6, 14) { c in
            f(c, 2, 0, 2, 7, rgb(100,70,42)); f(c, 2, 6, 2, 1, rgb(120,88,52))
            f(c, 1, 7, 4, 4, rgb(255,155,50)); f(c, 2, 8, 2, 5, rgb(255,218,95))
            px(c, 3, 12, rgb(255,240,150))
        },
    ]
    lazy var glowTex: SKTexture = {
        let r = 80
        let img = NSImage(size: NSSize(width: r*2, height: r*2))
        img.lockFocus()
        let ctx = NSGraphicsContext.current!.cgContext
        let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [NSColor(red:1,green:0.65,blue:0.25,alpha:0.25).cgColor,
                     NSColor(red:1,green:0.4,blue:0.1,alpha:0).cgColor] as CFArray,
            locations: [0, 1])!
        ctx.drawRadialGradient(grad,
            startCenter: CGPoint(x: r, y: r), startRadius: 0,
            endCenter: CGPoint(x: r, y: r), endRadius: CGFloat(r), options: [])
        img.unlockFocus()
        return SKTexture(image: img)
    }()
    // ── Roll frames (2-frame tumble) ──
    lazy var playerRoll2: SKTexture = {
        sprite(18, 14) { c in
            f(c, 2, 3, 14, 9, OL)
            f(c, 3, 4, 12, 7, C2); f(c, 4, 5, 10, 5, C1)
            f(c, 5, 6, 8, 3, A2); f(c, 6, 7, 6, 1, A3)
            px(c, 4, 6, EG); px(c, 5, 6, EG)
        }
    }()

    // ── Bone projectile ──
    lazy var boneTex: SKTexture = sprite(8, 4) { c in
        f(c, 0, 1, 8, 2, BO); f(c, 1, 0, 2, 4, BN); f(c, 5, 0, 2, 4, BN)
        px(c, 3, 2, BN); px(c, 4, 2, BN)
    }

    lazy var healthOrb: SKTexture = sprite(8, 8) { c in
        f(c, 1, 1, 6, 6, rgb(35,160,60)); f(c, 2, 2, 4, 4, rgb(55,210,85))
        f(c, 3, 3, 2, 2, rgb(120,255,150)); px(c, 4, 5, rgb(200,255,210))
    }
    lazy var vignetteTex: SKTexture = {
        let w = Int(WIN_W), h = Int(WIN_H)
        let img = NSImage(size: NSSize(width: w, height: h))
        img.lockFocus()
        let ctx = NSGraphicsContext.current!.cgContext
        let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [NSColor(red:0,green:0,blue:0,alpha:0).cgColor,
                     NSColor(red:0,green:0,blue:0,alpha:0.55).cgColor] as CFArray,
            locations: [0.35, 1])!
        let cx = CGFloat(w)/2, cy = CGFloat(h)/2
        ctx.drawRadialGradient(grad,
            startCenter: CGPoint(x: cx, y: cy), startRadius: 0,
            endCenter: CGPoint(x: cx, y: cy), endRadius: max(cx, cy), options: [])
        img.unlockFocus()
        return SKTexture(image: img)
    }()
}

// ══════════════════════════════════════════════════════════════
// MARK: - LEVEL GENERATOR
// ══════════════════════════════════════════════════════════════
func generateLevel(_ floor: Int) -> ([[Tile]], CGPoint, CGPoint, [EnemySpawn], [TorchInfo]) {
    var tiles = Array(repeating: Array(repeating: Tile.bgWall, count: LEVEL_COLS), count: LEVEL_ROWS)
    var enemies: [EnemySpawn] = []
    var torches: [TorchInfo] = []

    // Ground
    for c in 0..<LEVEL_COLS { tiles[0][c] = .wall; tiles[1][c] = .floor }
    // Side walls
    for r in 0..<LEVEL_ROWS { tiles[r][0] = .wall; tiles[r][LEVEL_COLS-1] = .wall }

    // Platforms at multiple heights
    for h in [5, 9, 13, 17] {
        var x = Int.random(in: 3...6)
        while x < LEVEL_COLS - 10 {
            let w = Int.random(in: 5...12)
            for c in x..<min(x + w, LEVEL_COLS - 2) {
                tiles[h][c] = h <= 5 ? .floor : .platform
            }
            if Bool.random() || floor > 2 {
                let et = floor < 3 ? 0 : (floor < 6 ? Int.random(in: 0...1) : Int.random(in: 0...2))
                enemies.append(EnemySpawn(x: CGFloat(x + w/2) * TS + TS/2,
                                          y: CGFloat(h + 1) * TS, type: et))
            }
            x += w + Int.random(in: 3...7)
        }
    }

    // Pillars
    for _ in 0..<min(3 + floor, 8) {
        let px = Int.random(in: 5..<(LEVEL_COLS - 10))
        let py = Int.random(in: 2...6)
        for r in py..<min(py + Int.random(in: 3...5), LEVEL_ROWS - 2) {
            tiles[r][px] = .wall; tiles[r][px + 1] = .wall
        }
    }

    // Ground enemies
    for _ in 0..<(2 + floor) {
        let ex = CGFloat(Int.random(in: 8..<(LEVEL_COLS - 10))) * TS
        enemies.append(EnemySpawn(x: ex, y: 2 * TS, type: floor < 3 ? 0 : Int.random(in: 0...1)))
    }

    // Bats
    if floor >= 3 {
        for _ in 0..<max(1, floor - 2) {
            enemies.append(EnemySpawn(
                x: CGFloat(Int.random(in: 10..<(LEVEL_COLS-10))) * TS,
                y: CGFloat(Int.random(in: 10...18)) * TS, type: 2))
        }
    }

    // Torches
    for c in stride(from: 4, to: LEVEL_COLS - 4, by: Int.random(in: 8...12)) {
        torches.append(TorchInfo(x: CGFloat(c) * TS + TS/2, y: 2 * TS + TS/2 + 4))
        if Int.random(in: 0...2) == 0 {
            torches.append(TorchInfo(x: CGFloat(c) * TS + TS/2, y: 10 * TS + TS/2))
        }
    }

    // Exit door
    tiles[2][LEVEL_COLS - 4] = .door

    let spawn = CGPoint(x: 3 * TS, y: 2 * TS + 4)
    let exit = CGPoint(x: CGFloat(LEVEL_COLS - 4) * TS + TS/2, y: 2 * TS + TS/2)
    return (tiles, spawn, exit, enemies, torches)
}

// ══════════════════════════════════════════════════════════════
// MARK: - ENEMY
// ══════════════════════════════════════════════════════════════
class Enemy {
    var node: SKSpriteNode
    var type: Int
    var pos: CGPoint
    var vel = CGPoint.zero
    var hp: Int
    var facing: CGFloat = -1
    var startX: CGFloat
    var attackCD: CGFloat = 0
    var stunTimer: CGFloat = 0
    var flashTimer: CGFloat = 0
    var sineT: CGFloat = 0
    var onGround = false

    init(type: Int, pos: CGPoint, tex: SKTexture) {
        self.type = type; self.pos = pos; self.startX = pos.x
        self.hp = type == 1 ? 3 : (type == 2 ? 1 : 2)
        self.node = SKSpriteNode(texture: tex)
        self.node.anchorPoint = CGPoint(x: 0.5, y: 0) // bottom-center so feet align with floor
        self.node.setScale(S)
        self.node.zPosition = 5
        self.node.position = pos
    }
}

// ══════════════════════════════════════════════════════════════
// MARK: - UPGRADES
// ══════════════════════════════════════════════════════════════
struct Upgrade {
    let id: String
    let name: String
    let desc: String
    let icon: NSColor // tint color for icon
}

let ALL_UPGRADES: [Upgrade] = [
    Upgrade(id: "maxhp",    name: "Vitality",       desc: "+1 Max HP & full heal",      icon: rgb(50,200,80)),
    Upgrade(id: "damage",   name: "Sharpened Blade", desc: "Attacks deal +1 damage",     icon: rgb(220,220,240)),
    Upgrade(id: "speed",    name: "Swift Boots",    desc: "+20% movement speed",         icon: rgb(80,180,255)),
    Upgrade(id: "reach",    name: "Long Sword",     desc: "+30% attack reach",           icon: rgb(200,150,50)),
    Upgrade(id: "crit",     name: "Lethal Strike",  desc: "25% chance for 2x damage",    icon: rgb(255,60,60)),
    Upgrade(id: "armor",    name: "Thick Skin",     desc: "Longer invincibility on hit", icon: rgb(160,140,120)),
    Upgrade(id: "vampiric", name: "Blood Drain",    desc: "Heal 1 HP every 5 kills",     icon: rgb(180,30,60)),
    Upgrade(id: "walljump", name: "Wall Mastery",   desc: "Stronger wall jumps",         icon: rgb(140,100,200)),
    Upgrade(id: "roll",     name: "Shadow Step",    desc: "Faster, longer roll",         icon: rgb(80,60,120)),
    Upgrade(id: "attract",  name: "Magnetism",      desc: "Health orbs pulled to you",   icon: rgb(100,255,200)),
]

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// ══════════════════════════════════════════════════════════════
// MARK: - GAME SCENE
// ══════════════════════════════════════════════════════════════
class DungeonScene: SKScene {

    // Player
    var pPos = CGPoint.zero
    var pVel = CGPoint.zero
    var pHP = 5
    var pMaxHP = 5
    var pFacing: CGFloat = 1
    var pGround = false
    var pWallSlide = false
    var pCoyote: CGFloat = 0
    var pJumpBuf: CGFloat = 0
    var pInv: CGFloat = 0
    var pRollT: CGFloat = 0
    var pRollDir: CGFloat = 0
    var pAtkT: CGFloat = 0
    var pAtkPhase = 0
    var pAtkHit = false

    // Upgrade stats
    var bonusDmg = 0
    var spdMult: CGFloat = 1.0
    var reachMult: CGFloat = 1.0
    var critChance: CGFloat = 0
    var invMult: CGFloat = 1.0
    var vampKillCount = 0
    var vampiricActive = false
    var wallJumpMult: CGFloat = 1.0
    var rollMult: CGFloat = 1.0
    var attractOrbs = false
    var acquiredUpgrades: [String] = []

    // Game
    var state = "menu" // menu, playing, dead, upgrading
    var floorNum = 1
    var kills = 0
    var tiles: [[Tile]] = []
    var exitPos = CGPoint.zero
    var hitPause: CGFloat = 0
    var shakeAmt: CGFloat = 0
    var lastT: TimeInterval = 0
    var elapsed: TimeInterval = 0

    // Input
    var keys: Set<UInt16> = []
    var heldKeys: Set<UInt16> = []  // tracks physical hold state (no repeat)
    var mouseDown = false

    // Nodes
    var pNode: SKSpriteNode!
    var cam: SKCameraNode!
    var levelNode: SKNode!
    var bgNode: SKNode!
    var fgNode: SKNode!
    var fgOverlay: SKNode!  // foreground tiles that render OVER the player
    var enemies: [Enemy] = []
    var healthOrbs: [SKSpriteNode] = []
    var projectiles: [(node: SKSpriteNode, vel: CGPoint, life: CGFloat)] = []
    var torchNodes: [(SKSpriteNode, SKSpriteNode)] = [] // (torch, glow)
    var dustParticles: [SKShapeNode] = []
    var vignette: SKSpriteNode!
    var flashNode: SKShapeNode!

    // Upgrade UI
    var upgradeNode: SKNode?
    var upgradeChoices: [Upgrade] = []
    var upgradeCards: [SKNode] = []

    // HUD
    var hudHP: SKShapeNode!
    var hudHPBg: SKShapeNode!
    var hudFloor: SKLabelNode!
    var hudKills: SKLabelNode!
    var menuNode: SKNode!
    var deathNode: SKNode!

    // ── Setup ──
    override func didMove(to view: SKView) {
        backgroundColor = BG_COL
        anchorPoint = .zero

        cam = SKCameraNode()
        cam.position = CGPoint(x: WIN_W/2, y: WIN_H/2)
        addChild(cam); camera = cam

        bgNode = SKNode(); bgNode.zPosition = -2; addChild(bgNode)
        fgNode = SKNode(); fgNode.zPosition = 1; addChild(fgNode)          // solid tiles behind player
        levelNode = SKNode(); levelNode.zPosition = 5; addChild(levelNode)  // torches, effects, enemies
        fgOverlay = SKNode(); fgOverlay.zPosition = 15; addChild(fgOverlay) // tiles that render OVER player

        // Player sprite
        pNode = SKSpriteNode(texture: Tex.shared.playerIdle[0])
        pNode.anchorPoint = CGPoint(x: 0.5, y: 0)  // bottom-center so feet align with floor
        pNode.setScale(S); pNode.zPosition = 10; pNode.isHidden = true
        addChild(pNode)  // zPosition 10: behind fgOverlay(15), in front of fgNode(1)

        // Vignette (attached to camera)
        vignette = SKSpriteNode(texture: Tex.shared.vignetteTex)
        vignette.size = CGSize(width: WIN_W, height: WIN_H)
        vignette.zPosition = 90
        cam.addChild(vignette)

        // Flash overlay
        flashNode = SKShapeNode(rectOf: CGSize(width: WIN_W+200, height: WIN_H+200))
        flashNode.fillColor = .red; flashNode.strokeColor = .clear
        flashNode.alpha = 0; flashNode.zPosition = 85
        cam.addChild(flashNode)

        setupHUD()
        setupMenu()

        // Mouse tracking
        let ta = NSTrackingArea(rect: view.bounds,
            options: [.activeAlways, .mouseMoved, .inVisibleRect], owner: view, userInfo: nil)
        view.addTrackingArea(ta)
    }

    func setupHUD() {
        hudHPBg = SKShapeNode(rectOf: CGSize(width: 160, height: 14), cornerRadius: 3)
        hudHPBg.fillColor = rgb(40, 10, 10); hudHPBg.strokeColor = rgb(120, 30, 30)
        hudHPBg.lineWidth = 1; hudHPBg.position = CGPoint(x: -WIN_W/2 + 90, y: WIN_H/2 - 25)
        hudHPBg.zPosition = 95; cam.addChild(hudHPBg)

        hudHP = SKShapeNode(rectOf: CGSize(width: 154, height: 10), cornerRadius: 2)
        hudHP.fillColor = rgb(50, 200, 80); hudHP.strokeColor = .clear
        hudHP.position = CGPoint(x: -WIN_W/2 + 90, y: WIN_H/2 - 25)
        hudHP.zPosition = 96; cam.addChild(hudHP)

        hudFloor = SKLabelNode(fontNamed: "Courier-Bold")
        hudFloor.fontSize = 16; hudFloor.fontColor = NSColor(white: 0.45, alpha: 1)
        hudFloor.position = CGPoint(x: 0, y: WIN_H/2 - 28)
        hudFloor.zPosition = 95; cam.addChild(hudFloor)

        hudKills = SKLabelNode(fontNamed: "Courier-Bold")
        hudKills.fontSize = 14; hudKills.fontColor = NSColor(white: 0.4, alpha: 1)
        hudKills.horizontalAlignmentMode = .right
        hudKills.position = CGPoint(x: WIN_W/2 - 15, y: WIN_H/2 - 28)
        hudKills.zPosition = 95; cam.addChild(hudKills)

        for n: SKNode in [hudHPBg!, hudHP!, hudFloor!, hudKills!] { n.isHidden = true }
    }

    func setupMenu() {
        menuNode = SKNode(); menuNode.zPosition = 100; cam.addChild(menuNode)

        let title = SKLabelNode(fontNamed: "Courier-Bold")
        title.text = "CRYPTS OF SHADOW"; title.fontSize = 52; title.fontColor = rgb(160, 80, 220)
        title.position = CGPoint(x: 0, y: 80); menuNode.addChild(title)

        let glow = title.copy() as! SKLabelNode
        glow.fontColor = rgb(120, 50, 180); glow.alpha = 0.3
        glow.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.15, duration: 2), SKAction.fadeAlpha(to: 0.4, duration: 2)])))
        menuNode.addChild(glow)

        let sub = SKLabelNode(fontNamed: "Courier")
        sub.text = "A ROGUELIKE DUNGEON CRAWLER"; sub.fontSize = 13
        sub.fontColor = NSColor(white: 0.38, alpha: 1); sub.position = CGPoint(x: 0, y: 30)
        menuNode.addChild(sub)

        let start = SKLabelNode(fontNamed: "Courier-Bold")
        start.text = "CLICK TO ENTER THE CRYPTS"; start.fontSize = 18; start.fontColor = .white
        start.position = CGPoint(x: 0, y: -40)
        start.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.25, duration: 0.9), SKAction.fadeAlpha(to: 1, duration: 0.9)])))
        menuNode.addChild(start)

        let ctrl = SKLabelNode(fontNamed: "Courier")
        ctrl.text = "A/D move  |  Up/W/Space jump  |  J/Click attack  |  K/Shift roll"
        ctrl.fontSize = 11; ctrl.fontColor = NSColor(white: 0.3, alpha: 1)
        ctrl.position = CGPoint(x: 0, y: -120); menuNode.addChild(ctrl)
    }

    func showDeath() {
        deathNode = SKNode(); deathNode.zPosition = 100; cam.addChild(deathNode)
        deathNode.alpha = 0
        deathNode.run(SKAction.fadeAlpha(to: 1, duration: 0.5))

        let bg = SKShapeNode(rectOf: CGSize(width: WIN_W, height: WIN_H))
        bg.fillColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.65); bg.strokeColor = .clear
        deathNode.addChild(bg)

        let t = SKLabelNode(fontNamed: "Courier-Bold")
        t.text = "YOU DIED"; t.fontSize = 56; t.fontColor = rgb(200, 30, 30)
        t.position = CGPoint(x: 0, y: 60); deathNode.addChild(t)

        let s = SKLabelNode(fontNamed: "Courier-Bold")
        s.text = "Floor \(floorNum)  |  Kills \(kills)"; s.fontSize = 18
        s.fontColor = NSColor(white: 0.5, alpha: 1); s.position = CGPoint(x: 0, y: 0)
        deathNode.addChild(s)

        let r = SKLabelNode(fontNamed: "Courier-Bold")
        r.text = "CLICK TO RESTART"; r.fontSize = 18; r.fontColor = .white
        r.position = CGPoint(x: 0, y: -60); r.alpha = 0
        r.run(SKAction.sequence([SKAction.wait(forDuration: 1.5),
            SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 1, duration: 0.7), SKAction.fadeAlpha(to: 0.3, duration: 0.7)]))]))
        deathNode.addChild(r)
    }

    // ── Level Loading ──
    func loadLevel(_ fl: Int) {
        // Clear old
        bgNode.removeAllChildren(); fgNode.removeAllChildren(); levelNode.removeAllChildren()
        fgOverlay.removeAllChildren()
        for e in enemies { e.node.removeFromParent() }; enemies.removeAll()
        for h in healthOrbs { h.removeFromParent() }; healthOrbs.removeAll()
        for p in projectiles { p.node.removeFromParent() }; projectiles.removeAll()
        torchNodes.removeAll(); dustParticles.removeAll()

        let (t, spawn, exit, spawns, torchs) = generateLevel(fl)
        tiles = t; exitPos = exit

        // Place tiles with proper layering
        // Solid tiles at row >= 3 go on fgOverlay (render OVER player/enemies)
        // so characters appear integrated with the environment
        let tex = Tex.shared
        for r in 0..<LEVEL_ROWS {
            for c in 0..<LEVEL_COLS {
                let tile = tiles[r][c]
                let tileT: SKTexture?
                switch tile {
                case .wall: tileT = tex.wallTex
                case .floor: tileT = tex.floorTex
                case .platform: tileT = tex.platformTex
                case .bgWall: tileT = tex.bgWallTex
                case .door: tileT = tex.doorTex
                default: continue
                }
                if let t = tileT {
                    let n = SKSpriteNode(texture: t)
                    n.setScale(S)
                    n.position = CGPoint(x: CGFloat(c) * TS + TS/2, y: CGFloat(r) * TS + TS/2)
                    if tile == .door { n.position.y += TS/2 }
                    if tile == .bgWall {
                        bgNode.addChild(n)
                    } else if tile == .wall && r >= 4 {
                        // Upper walls render over player for depth illusion
                        fgOverlay.addChild(n)
                        n.alpha = 0.65 // slight transparency so player is visible behind
                    } else {
                        fgNode.addChild(n)
                    }
                }
            }
        }

        // Torches
        for ti in torchs {
            let tn = SKSpriteNode(texture: tex.torchFrames[0])
            tn.setScale(S); tn.position = CGPoint(x: ti.x, y: ti.y); tn.zPosition = 3
            tn.run(SKAction.repeatForever(SKAction.animate(with: tex.torchFrames, timePerFrame: 0.25)))
            levelNode.addChild(tn)
            let gn = SKSpriteNode(texture: tex.glowTex)
            gn.position = CGPoint(x: ti.x, y: ti.y + 10); gn.zPosition = 2
            gn.blendMode = .add; gn.alpha = 0.6; gn.setScale(2.5)
            gn.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.4, duration: 0.4 + Double.random(in: 0...0.3)),
                SKAction.fadeAlpha(to: 0.65, duration: 0.4 + Double.random(in: 0...0.3))])))
            levelNode.addChild(gn)
            torchNodes.append((tn, gn))
        }

        // Enemies
        for sp in spawns {
            let etex: SKTexture
            switch sp.type {
            case 0: etex = tex.zombieWalk[0]
            case 1: etex = tex.skeletonWalk[0]
            default: etex = tex.batFly[0]
            }
            let e = Enemy(type: sp.type, pos: CGPoint(x: sp.x, y: sp.y), tex: etex)
            enemies.append(e); levelNode.addChild(e.node)
        }

        // Ambient dust
        for _ in 0..<30 {
            let d = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...1.5))
            d.fillColor = NSColor(white: 0.25, alpha: CGFloat.random(in: 0.15...0.35))
            d.strokeColor = .clear
            d.position = CGPoint(x: CGFloat.random(in: 0...CGFloat(LEVEL_COLS)*TS),
                                 y: CGFloat.random(in: 0...CGFloat(LEVEL_ROWS)*TS))
            d.zPosition = 15
            levelNode.addChild(d)
            dustParticles.append(d)
        }

        // Reset player
        pPos = spawn; pVel = .zero; pGround = false; pAtkT = 0; pRollT = 0
        pNode.isHidden = false; pNode.position = spawn
    }

    func startGame() {
        menuNode.isHidden = true
        if deathNode != nil { deathNode.removeFromParent(); deathNode = nil }
        // Reset all upgrade stats
        floorNum = 1; kills = 0; pMaxHP = 5; pHP = pMaxHP; pInv = 0
        bonusDmg = 0; spdMult = 1.0; reachMult = 1.0; critChance = 0
        invMult = 1.0; vampKillCount = 0; vampiricActive = false
        wallJumpMult = 1.0; rollMult = 1.0; attractOrbs = false
        acquiredUpgrades.removeAll()
        for n: SKNode in [hudHPBg!, hudHP!, hudFloor!, hudKills!] { n.isHidden = false }
        loadLevel(floorNum)
        state = "playing"
    }

    func nextFloor() {
        floorNum += 1
        pHP = min(pHP + 1, pMaxHP)
        showUpgradeScreen()
    }

    func proceedToNextFloor() {
        loadLevel(floorNum)
        showFloorText("FLOOR \(floorNum)")
        state = "playing"
    }

    // ── Upgrade Screen ──
    func showUpgradeScreen() {
        state = "upgrading"
        pNode.isHidden = true

        // Pick 3 random upgrades (avoid duplicates of single-use ones)
        var pool = ALL_UPGRADES.filter { u in
            // Allow stacking for damage/speed/reach/crit, but not walljump/roll/attract/vampiric if already owned
            let singleUse = ["walljump", "vampiric", "attract"]
            if singleUse.contains(u.id) && acquiredUpgrades.contains(u.id) { return false }
            return true
        }
        pool.shuffle()
        upgradeChoices = Array(pool.prefix(3))
        upgradeCards.removeAll()

        upgradeNode = SKNode()
        upgradeNode!.zPosition = 100
        cam.addChild(upgradeNode!)

        // Dim background
        let bg = SKShapeNode(rectOf: CGSize(width: WIN_W + 200, height: WIN_H + 200))
        bg.fillColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.75); bg.strokeColor = .clear
        upgradeNode!.addChild(bg)

        // Title
        let title = SKLabelNode(fontNamed: "Courier-Bold")
        title.text = "CHOOSE AN UPGRADE"; title.fontSize = 32; title.fontColor = rgb(255, 220, 80)
        title.position = CGPoint(x: 0, y: 200); upgradeNode!.addChild(title)

        let floorLbl = SKLabelNode(fontNamed: "Courier")
        floorLbl.text = "Floor \(floorNum) reached"; floorLbl.fontSize = 14
        floorLbl.fontColor = NSColor(white: 0.45, alpha: 1)
        floorLbl.position = CGPoint(x: 0, y: 168); upgradeNode!.addChild(floorLbl)

        // Cards
        let cardW: CGFloat = 260
        let cardH: CGFloat = 280
        let gap: CGFloat = 30
        let totalW = 3 * cardW + 2 * gap
        let startX = -totalW / 2 + cardW / 2

        for (i, upg) in upgradeChoices.enumerated() {
            let card = SKNode()
            card.position = CGPoint(x: startX + CGFloat(i) * (cardW + gap), y: -20)

            // Card background
            let cardBg = SKShapeNode(rectOf: CGSize(width: cardW, height: cardH), cornerRadius: 8)
            cardBg.fillColor = rgb(28, 24, 42); cardBg.strokeColor = rgb(80, 60, 120)
            cardBg.lineWidth = 2; card.addChild(cardBg)

            // Icon circle
            let iconCircle = SKShapeNode(circleOfRadius: 28)
            iconCircle.fillColor = upg.icon.withAlphaComponent(0.2)
            iconCircle.strokeColor = upg.icon; iconCircle.lineWidth = 2
            iconCircle.position = CGPoint(x: 0, y: 70); card.addChild(iconCircle)

            let iconDot = SKShapeNode(circleOfRadius: 12)
            iconDot.fillColor = upg.icon; iconDot.strokeColor = .clear
            iconDot.position = CGPoint(x: 0, y: 70); card.addChild(iconDot)

            // Name
            let name = SKLabelNode(fontNamed: "Courier-Bold")
            name.text = upg.name; name.fontSize = 18; name.fontColor = .white
            name.position = CGPoint(x: 0, y: 20); card.addChild(name)

            // Description
            let desc = SKLabelNode(fontNamed: "Courier")
            desc.text = upg.desc; desc.fontSize = 12
            desc.fontColor = NSColor(white: 0.55, alpha: 1)
            desc.position = CGPoint(x: 0, y: -10)
            desc.preferredMaxLayoutWidth = cardW - 30
            desc.numberOfLines = 2
            card.addChild(desc)

            // Key hint
            let hint = SKLabelNode(fontNamed: "Courier-Bold")
            hint.text = "[ \(i+1) ]"; hint.fontSize = 22; hint.fontColor = rgb(160, 140, 200)
            hint.position = CGPoint(x: 0, y: -70); card.addChild(hint)

            upgradeNode!.addChild(card)
            upgradeCards.append(card)

            // Entrance animation
            card.alpha = 0; card.position.y -= 30
            card.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.12),
                SKAction.group([
                    SKAction.fadeAlpha(to: 1, duration: 0.3),
                    SKAction.moveBy(x: 0, y: 30, duration: 0.3)])]))
        }
    }

    func selectUpgrade(_ index: Int) {
        guard index < upgradeChoices.count else { return }
        let upg = upgradeChoices[index]
        acquiredUpgrades.append(upg.id)

        switch upg.id {
        case "maxhp": pMaxHP += 1; pHP = pMaxHP
        case "damage": bonusDmg += 1
        case "speed": spdMult += 0.2
        case "reach": reachMult += 0.3
        case "crit": critChance = min(critChance + 0.25, 0.75)
        case "armor": invMult += 0.4
        case "vampiric": vampiricActive = true
        case "walljump": wallJumpMult = 1.35
        case "roll": rollMult += 0.3
        case "attract": attractOrbs = true
        default: break
        }

        // Flash the selected card
        if let card = upgradeCards[safe: index] {
            let flash = SKShapeNode(rectOf: CGSize(width: 260, height: 280), cornerRadius: 8)
            flash.fillColor = .white; flash.strokeColor = .clear; flash.alpha = 0.5
            card.addChild(flash)
            flash.run(SKAction.sequence([SKAction.fadeAlpha(to: 0, duration: 0.3)]))
        }

        // Dismiss upgrade screen after short delay
        upgradeNode?.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            SKAction.fadeAlpha(to: 0, duration: 0.3),
            SKAction.run { [weak self] in
                self?.upgradeNode?.removeFromParent()
                self?.upgradeNode = nil
                self?.pNode.isHidden = false
                self?.proceedToNextFloor()
            }]))
    }

    func showFloorText(_ txt: String) {
        let l = SKLabelNode(fontNamed: "Courier-Bold")
        l.text = txt; l.fontSize = 42; l.fontColor = .white; l.zPosition = 80
        cam.addChild(l)
        l.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 1, duration: 0.3), SKAction.wait(forDuration: 0.8),
            SKAction.fadeAlpha(to: 0, duration: 0.5), SKAction.removeFromParent()]))
    }

    func die() {
        state = "dead"; pNode.isHidden = true; elapsed = 0
        spawnBlood(at: pPos, count: 25)
        shakeAmt = 15
        showDeath()
    }

    // ── Input ──
    override func keyDown(with event: NSEvent) {
        if !event.isARepeat { keys.insert(event.keyCode) }
        heldKeys.insert(event.keyCode)
        // Upgrade selection: 1=18, 2=19, 3=20
        if state == "upgrading" && !event.isARepeat {
            if event.keyCode == 18 { selectUpgrade(0) }
            else if event.keyCode == 19 { selectUpgrade(1) }
            else if event.keyCode == 20 { selectUpgrade(2) }
        }
    }
    override func keyUp(with event: NSEvent) {
        keys.remove(event.keyCode)
        heldKeys.remove(event.keyCode)
    }
    override func mouseDown(with event: NSEvent) {
        mouseDown = true
        if state == "menu" { startGame() }
        else if state == "dead" && elapsed > 1.5 { startGame() }
        else if state == "upgrading" {
            // Check if click is on a card
            let loc = event.location(in: self)
            let camLoc = convert(loc, to: cam)
            for (i, card) in upgradeCards.enumerated() {
                let cardPos = card.position
                if abs(camLoc.x - cardPos.x) < 130 && abs(camLoc.y - cardPos.y) < 140 {
                    selectUpgrade(i); break
                }
            }
        }
    }
    override func mouseUp(with event: NSEvent) { mouseDown = false }
    override func mouseMoved(with event: NSEvent) {}

    // ── Main Update ──
    override func update(_ currentTime: TimeInterval) {
        var dt: CGFloat
        if lastT == 0 { dt = 1.0/60.0 } else { dt = CGFloat(min(currentTime - lastT, 1.0/30.0)) }
        lastT = currentTime
        elapsed += Double(dt)

        if state == "dead" || state == "menu" || state == "upgrading" {
            updateDust(dt); shakeAmt *= max(0, 1 - dt * 8)
            flashNode.alpha *= CGFloat(max(0, 1 - dt * 6))
            updateCamera(); return
        }

        // Hit pause
        if hitPause > 0 { hitPause -= dt; return }

        updatePlayer(dt)
        updateEnemies(dt)
        updateProjectiles(dt)
        checkCombat()
        checkExit()
        updateOrbs(dt)
        updateDust(dt)
        updateHUD()
        updateCamera()
        shakeAmt *= max(0, 1 - dt * 10)
        flashNode.alpha *= CGFloat(max(0, 1 - dt * 6))
    }

    // ── Player ──
    func updatePlayer(_ dt: CGFloat) {
        // Input: heldKeys for continuous, keys for one-shot triggers
        let kA = heldKeys.contains(0) || heldKeys.contains(123)   // A / Left
        let kD = heldKeys.contains(2) || heldKeys.contains(124)   // D / Right
        let kJ = heldKeys.contains(38) || mouseDown                // J / Click

        // Roll: one-shot from keys (like jump)
        let rollPressed = keys.contains(40) || keys.contains(56)  // K / Shift
        if rollPressed { keys.remove(40); keys.remove(56) }

        // Jump: one-shot from keys
        let jumpPressed = keys.contains(126) || keys.contains(13) || keys.contains(49)  // Up Arrow / W / Space
        if jumpPressed {
            pJumpBuf = JUMP_BUF
            keys.remove(126); keys.remove(13); keys.remove(49)
        }

        let effectiveMoveSPD = MOVE_SPD * spdMult
        let effectiveRollSPD = ROLL_SPD * rollMult
        let effectiveRollDUR = ROLL_DUR * (1 + (rollMult - 1) * 0.5)

        // Roll
        if pRollT > 0 {
            pRollT -= dt
            pVel.x = pRollDir * effectiveRollSPD
            pInv = 0.25  // fully invincible during roll + 0.25s after
        } else {
            // Movement
            var dx: CGFloat = 0
            if kA { dx -= 1; pFacing = -1 }
            if kD { dx += 1; pFacing = 1 }
            if pAtkT <= 0 { pVel.x = dx * effectiveMoveSPD }

            // Roll trigger: just press K/Shift, rolls in facing direction, works on ground or air
            if rollPressed && pRollT <= -0.1 {
                pRollT = effectiveRollDUR; pRollDir = pFacing
            }
        }

        // Wall detection
        let wallL = isSolid(pPos.x - 14, pPos.y + 10) && !isSolid(pPos.x - 14, pPos.y + 55)
        let wallR = isSolid(pPos.x + 14, pPos.y + 10) && !isSolid(pPos.x + 14, pPos.y + 55)
        pWallSlide = false
        if !pGround && pVel.y < 0 {
            if (wallL && kA) || (wallR && kD) {
                pVel.y = max(pVel.y, WALL_SLIDE)
                pWallSlide = true
            }
        }

        // Jump buffer decrement
        pJumpBuf -= dt; pCoyote -= dt

        // Jump execution
        if pJumpBuf > 0 {
            if pCoyote > 0 {
                pVel.y = JUMP_VEL; pCoyote = 0; pJumpBuf = 0
            } else if pWallSlide {
                pVel.y = WALL_JUMP_V * wallJumpMult
                pVel.x = (wallL ? WALL_JUMP_H : -WALL_JUMP_H) * wallJumpMult
                pFacing = wallL ? 1 : -1
                pJumpBuf = 0
            }
        }

        // Gravity
        pVel.y += GRAVITY * dt
        pVel.y = max(pVel.y, MAX_FALL)

        // Move X
        pPos.x += pVel.x * dt
        resolveX()

        // Move Y
        let prevGround = pGround
        pGround = false
        pPos.y += pVel.y * dt
        resolveY()

        // Refresh coyote every frame on ground; on leaving ground, start countdown
        if pGround { pCoyote = COYOTE }
        else if prevGround && pVel.y <= 0 { pCoyote = COYOTE }

        // Clamp to level
        pPos.x = max(TS, min(CGFloat(LEVEL_COLS) * TS - TS, pPos.x))
        if pPos.y < -TS { pHP = 0 }

        // Attack (kJ uses heldKeys, already declared above)
        if kJ && pAtkT <= -0.15 && pRollT <= 0 {
            pAtkT = ATTACK_DUR; pAtkPhase = 0; pAtkHit = false
            mouseDown = false  // consume click
        }
        if pAtkT > 0 {
            pAtkT -= dt
            if pAtkT < ATTACK_DUR * 0.6 { pAtkPhase = 1 }
            if pAtkT < ATTACK_DUR * 0.3 { pAtkPhase = 2 }
        } else {
            pAtkT -= dt // cooldown counter
        }

        // Invincibility
        pInv -= dt

        // Death check
        if pHP <= 0 { die(); return }

        // Update sprite
        updatePlayerAnim()
        pNode.position = pPos
    }

    func updatePlayerAnim() {
        let tex = Tex.shared
        if pRollT > 0 {
            // Two-frame roll animation + spin
            let rollPct = 1 - (pRollT / (ROLL_DUR * (1 + (rollMult - 1) * 0.5)))
            pNode.texture = rollPct < 0.5 ? tex.playerRoll : tex.playerRoll2
            pNode.zRotation = pRollDir * rollPct * .pi * 2  // full spin
            // Dust trail particles
            if Int(elapsed * 30) % 3 == 0 {
                let d = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
                d.fillColor = NSColor(white: 0.4, alpha: 0.5); d.strokeColor = .clear
                d.position = CGPoint(x: pPos.x - pRollDir * 10, y: pPos.y + 4)
                d.zPosition = 9
                levelNode.addChild(d)
                d.run(SKAction.sequence([
                    SKAction.group([SKAction.fadeAlpha(to: 0, duration: 0.3),
                                    SKAction.scale(to: 0.2, duration: 0.3),
                                    SKAction.moveBy(x: -pRollDir * 15, y: 10, duration: 0.3)]),
                    SKAction.removeFromParent()]))
            }
        } else if pAtkT > 0 {
            let idx = min(pAtkPhase, tex.playerAttack.count - 1)
            pNode.texture = tex.playerAttack[idx]
        } else if !pGround && pVel.y > 50 {
            pNode.texture = tex.playerJump
        } else if !pGround && pVel.y < -50 {
            pNode.texture = tex.playerFall
        } else if abs(pVel.x) > 20 {
            let frame = Int(elapsed * 8) % tex.playerRun.count
            pNode.texture = tex.playerRun[frame]
        } else {
            pNode.texture = tex.playerIdle[0]
        }
        if pRollT <= 0 { pNode.zRotation = 0 }  // reset rotation after roll
        pNode.xScale = pFacing * S
        pNode.yScale = S
        // Flash during invincibility, but stay visible during roll
        if pRollT > 0 {
            pNode.alpha = 0.8
        } else {
            pNode.alpha = (pInv > 0 && sin(elapsed * 20) > 0) ? 0.3 : 1
        }
    }

    // ── Tile Collision ──
    func tileAt(_ sx: CGFloat, _ sy: CGFloat) -> Tile {
        let c = Int(sx / TS); let r = Int(sy / TS)
        guard c >= 0 && c < LEVEL_COLS && r >= 0 && r < LEVEL_ROWS else { return .wall }
        return tiles[r][c]
    }
    func isSolid(_ sx: CGFloat, _ sy: CGFloat) -> Bool {
        let t = tileAt(sx, sy); return t == .wall || t == .floor
    }
    func isPlatform(_ sx: CGFloat, _ sy: CGFloat) -> Bool { tileAt(sx, sy) == .platform }

    let PW: CGFloat = 20  // player collision width
    let PH: CGFloat = 56  // player collision height

    func resolveX() {
        if pVel.x > 0 {
            for dy in stride(from: CGFloat(4), through: PH - 4, by: PH/3) {
                if isSolid(pPos.x + PW/2, pPos.y + dy) {
                    pPos.x = Darwin.floor((pPos.x + PW/2) / TS) * TS - PW/2
                    pVel.x = 0; return
                }
            }
        } else if pVel.x < 0 {
            for dy in stride(from: CGFloat(4), through: PH - 4, by: PH/3) {
                if isSolid(pPos.x - PW/2, pPos.y + dy) {
                    pPos.x = ceil((pPos.x - PW/2) / TS) * TS + PW/2
                    pVel.x = 0; return
                }
            }
        }
    }

    func resolveY() {
        if pVel.y < 0 {
            // Check feet
            for dx: CGFloat in [-PW/2 + 4, 0, PW/2 - 4] {
                if isSolid(pPos.x + dx, pPos.y) {
                    pPos.y = ceil(pPos.y / TS) * TS
                    pVel.y = 0; pGround = true; return
                }
                // Platform (one-way)
                if isPlatform(pPos.x + dx, pPos.y) {
                    let platTop = ceil(pPos.y / TS) * TS
                    if pPos.y < platTop + 6 {
                        pPos.y = platTop; pVel.y = 0; pGround = true; return
                    }
                }
            }
        } else if pVel.y > 0 {
            for dx: CGFloat in [-PW/2 + 4, PW/2 - 4] {
                if isSolid(pPos.x + dx, pPos.y + PH) {
                    pPos.y = Darwin.floor((pPos.y + PH) / TS) * TS - PH
                    pVel.y = 0; return
                }
            }
        }
    }

    // ── Enemies ──
    func updateEnemies(_ dt: CGFloat) {
        let tex = Tex.shared
        for e in enemies {
            if e.stunTimer > 0 { e.stunTimer -= dt }
            if e.flashTimer > 0 {
                e.flashTimer -= dt
                e.node.colorBlendFactor = 1; e.node.color = .white
            } else {
                e.node.colorBlendFactor = 0
            }
            e.attackCD -= dt

            let dx = pPos.x - e.pos.x
            let dy = pPos.y - e.pos.y
            let dist = sqrt(dx*dx + dy*dy)

            if e.stunTimer > 0 {
                // Apply knockback velocity but don't AI
                if e.type != 2 {
                    e.vel.y += GRAVITY * dt
                    e.pos.x += e.vel.x * dt; e.pos.y += e.vel.y * dt
                    resolveEnemyY(e)
                } else {
                    e.pos.x += e.vel.x * dt; e.pos.y += e.vel.y * dt
                }
                e.node.position = e.pos; continue
            }

            switch e.type {
            case 0: // Zombie
                if dist < 550 {
                    e.vel.x = (dx > 0 ? 1 : -1) * 70; e.facing = dx > 0 ? 1 : -1
                } else {
                    let drift = e.pos.x - e.startX
                    if abs(drift) > 150 { e.vel.x = drift > 0 ? -50 : 50 }
                    else if abs(e.vel.x) < 10 { e.vel.x = Bool.random() ? 50 : -50 }
                    e.facing = e.vel.x > 0 ? 1 : -1
                }
                if dist < 55 && e.attackCD <= 0 { e.attackCD = 1.2; damagePlayer(1, from: e.pos) }
                e.vel.y += GRAVITY * dt
                e.pos.x += e.vel.x * dt; e.pos.y += e.vel.y * dt
                resolveEnemyX(e); resolveEnemyY(e)
                let frame = Int(elapsed * 3) % tex.zombieWalk.count
                e.node.texture = (e.attackCD > 0.8) ? tex.zombieAttack : tex.zombieWalk[frame]

            case 1: // Skeleton — ranged bone thrower
                if dist < 500 {
                    // Keep distance: back away if too close, approach if too far
                    if dist < 150 {
                        e.vel.x = (dx > 0 ? -1 : 1) * 80; e.facing = dx > 0 ? 1 : -1
                    } else if dist > 350 {
                        e.vel.x = (dx > 0 ? 1 : -1) * 80; e.facing = dx > 0 ? 1 : -1
                    } else {
                        e.vel.x *= 0.8; e.facing = dx > 0 ? 1 : -1
                    }
                    // Throw bone projectile
                    if e.attackCD <= 0 && dist < 450 {
                        e.attackCD = 1.8
                        spawnBoneProjectile(from: e.pos, toward: pPos)
                    }
                } else {
                    let drift = e.pos.x - e.startX
                    if abs(drift) > 200 { e.vel.x = drift > 0 ? -60 : 60 }
                    else if abs(e.vel.x) < 10 { e.vel.x = Bool.random() ? 60 : -60 }
                    e.facing = e.vel.x > 0 ? 1 : -1
                }
                e.vel.y += GRAVITY * dt
                e.pos.x += e.vel.x * dt; e.pos.y += e.vel.y * dt
                resolveEnemyX(e); resolveEnemyY(e)
                let frame = Int(elapsed * 4) % tex.skeletonWalk.count
                e.node.texture = (e.attackCD > 1.3) ? tex.skeletonAttack : tex.skeletonWalk[frame]

            case 2: // Bat
                e.sineT += dt * 3
                e.pos.y += sin(e.sineT) * 40 * dt
                if dist < 450 {
                    let angle = atan2(dy, dx)
                    e.pos.x += cos(angle) * 130 * dt
                    e.pos.y += sin(angle) * 90 * dt
                } else {
                    e.pos.x += e.vel.x * dt
                    if abs(e.pos.x - e.startX) > 200 { e.vel.x = -e.vel.x }
                    else if abs(e.vel.x) < 10 { e.vel.x = Bool.random() ? 60 : -60 }
                }
                e.facing = dx > 0 ? 1 : -1
                if dist < 40 && e.attackCD <= 0 { e.attackCD = 1.5; damagePlayer(1, from: e.pos) }
                let frame = Int(elapsed * 6) % tex.batFly.count
                e.node.texture = tex.batFly[frame]

            default: break
            }

            e.node.position = e.pos
            e.node.xScale = e.facing * S; e.node.yScale = S
        }
    }

    func resolveEnemyX(_ e: Enemy) {
        let hw: CGFloat = 18
        if e.vel.x > 0 && isSolid(e.pos.x + hw, e.pos.y + 10) {
            e.pos.x = Darwin.floor((e.pos.x + hw) / TS) * TS - hw; e.vel.x = -e.vel.x
        } else if e.vel.x < 0 && isSolid(e.pos.x - hw, e.pos.y + 10) {
            e.pos.x = ceil((e.pos.x - hw) / TS) * TS + hw; e.vel.x = -e.vel.x
        }
    }

    func resolveEnemyY(_ e: Enemy) {
        if e.vel.y < 0 {
            if isSolid(e.pos.x, e.pos.y) || isPlatform(e.pos.x, e.pos.y) {
                e.pos.y = ceil(e.pos.y / TS) * TS; e.vel.y = 0; e.onGround = true
            }
        }
    }

    // ── Combat ──
    func checkCombat() {
        guard pAtkT > 0 && pAtkPhase == 1 && !pAtkHit else { return }
        pAtkHit = true

        let reach = ATTACK_REACH * reachMult
        let hx = pFacing > 0 ? pPos.x + 5 : pPos.x - reach - 5
        let hitBox = CGRect(x: hx, y: pPos.y - 10, width: reach, height: 60)

        var dmg = 1 + bonusDmg
        let isCrit = Float.random(in: 0...1) < Float(critChance)
        if isCrit { dmg *= 2 }

        for e in enemies {
            let eBox = CGRect(x: e.pos.x - 18, y: e.pos.y, width: 36, height: 52)
            if hitBox.intersects(eBox) {
                e.hp -= dmg; e.flashTimer = 0.1; e.stunTimer = 0.3
                e.vel.x = pFacing * 250; e.vel.y = 120
                hitPause = 0.04; shakeAmt = max(shakeAmt, isCrit ? 10 : 5)
                spawnBlood(at: e.pos, count: isCrit ? 12 : 6)
                if isCrit {
                    // Crit flash
                    let critTxt = SKLabelNode(fontNamed: "Courier-Bold")
                    critTxt.text = "CRIT!"; critTxt.fontSize = 16
                    critTxt.fontColor = rgb(255, 80, 80); critTxt.position = CGPoint(x: e.pos.x, y: e.pos.y + 50); critTxt.zPosition = 50
                    levelNode.addChild(critTxt)
                    critTxt.run(SKAction.sequence([
                        SKAction.group([SKAction.moveBy(x: 0, y: 30, duration: 0.5), SKAction.fadeAlpha(to: 0, duration: 0.5)]),
                        SKAction.removeFromParent()]))
                }
                if e.hp <= 0 { killEnemy(e) }
            }
        }
    }

    func killEnemy(_ e: Enemy) {
        spawnBlood(at: e.pos, count: 18)
        kills += 1; shakeAmt = max(shakeAmt, 8)
        // Vampiric heal
        if vampiricActive {
            vampKillCount += 1
            if vampKillCount >= 5 { vampKillCount = 0; pHP = min(pHP + 1, pMaxHP) }
        }
        // Health drop
        if Float.random(in: 0...1) < 0.25 {
            let orb = SKSpriteNode(texture: Tex.shared.healthOrb)
            orb.setScale(S); orb.position = e.pos; orb.zPosition = 6
            orb.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.moveBy(x: 0, y: 8, duration: 0.6),
                SKAction.moveBy(x: 0, y: -8, duration: 0.6)])))
            levelNode.addChild(orb); healthOrbs.append(orb)
        }
        // Floating text
        let txt = SKLabelNode(fontNamed: "Courier-Bold")
        txt.text = "+\([10,25,15][e.type])"; txt.fontSize = 14
        txt.fontColor = rgb(255, 220, 80); txt.position = e.pos; txt.zPosition = 50
        levelNode.addChild(txt)
        txt.run(SKAction.sequence([
            SKAction.group([SKAction.moveBy(x: 0, y: 40, duration: 0.7),
                            SKAction.fadeAlpha(to: 0, duration: 0.7)]),
            SKAction.removeFromParent()]))
        e.node.removeFromParent()
        enemies.removeAll { $0 === e }
    }

    func damagePlayer(_ dmg: Int, from: CGPoint) {
        guard pInv <= 0 else { return }
        pHP -= dmg; pInv = INV_TIME * invMult
        pVel.x = (pPos.x > from.x ? 1 : -1) * 200; pVel.y = 150
        shakeAmt = 12
        flashNode.fillColor = rgb(200, 30, 30)
        flashNode.alpha = 0.35
        spawnBlood(at: pPos, count: 8)
    }

    // ── Particles ──
    func spawnBlood(at pos: CGPoint, count: Int) {
        for _ in 0..<count {
            let p = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3.5))
            p.fillColor = rgb(Int.random(in: 140...200), Int.random(in: 15...45), Int.random(in: 15...35))
            p.strokeColor = .clear; p.position = pos; p.zPosition = 12
            levelNode.addChild(p)
            let a = CGFloat.random(in: 0...(.pi * 2))
            let spd = CGFloat.random(in: 60...200)
            let life = CGFloat.random(in: 0.3...0.6)
            p.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(by: CGVector(dx: cos(a)*spd*life, dy: sin(a)*spd*life), duration: TimeInterval(life)),
                    SKAction.fadeAlpha(to: 0, duration: TimeInterval(life)),
                    SKAction.scale(to: 0.1, duration: TimeInterval(life))]),
                SKAction.removeFromParent()]))
        }
    }

    func updateDust(_ dt: CGFloat) {
        for d in dustParticles {
            d.position.x += CGFloat.random(in: -5...5) * dt
            d.position.y += CGFloat.random(in: -2...4) * dt
        }
    }

    func updateOrbs(_ dt: CGFloat) {
        var toRemove: [Int] = []
        for (i, orb) in healthOrbs.enumerated() {
            let dx = pPos.x - orb.position.x
            let dy = pPos.y + PH/2 - orb.position.y
            let dist = sqrt(dx*dx + dy*dy)
            // Magnetism: pull orbs toward player
            if attractOrbs && dist < 200 && dist > 5 {
                orb.position.x += dx / dist * 250 * dt
                orb.position.y += dy / dist * 250 * dt
            }
            if dist < 40 {
                pHP = min(pHP + 1, pMaxHP); toRemove.append(i)
                orb.run(SKAction.sequence([
                    SKAction.group([SKAction.scale(to: 2, duration: 0.2), SKAction.fadeAlpha(to: 0, duration: 0.2)]),
                    SKAction.removeFromParent()]))
            }
        }
        for i in toRemove.reversed() { healthOrbs.remove(at: i) }
    }

    // ── Bone Projectiles ──
    func spawnBoneProjectile(from pos: CGPoint, toward target: CGPoint) {
        let bone = SKSpriteNode(texture: Tex.shared.boneTex)
        bone.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        bone.setScale(S); bone.position = CGPoint(x: pos.x, y: pos.y + 35)
        bone.zPosition = 8
        levelNode.addChild(bone)
        let dx = target.x - pos.x
        let dy = (target.y + 25) - (pos.y + 35)
        let d = sqrt(dx*dx + dy*dy)
        let spd: CGFloat = 320
        let vx = (dx / max(d, 1)) * spd
        let vy = (dy / max(d, 1)) * spd
        bone.zRotation = atan2(dy, dx)
        projectiles.append((node: bone, vel: CGPoint(x: vx, y: vy), life: 2.5))
    }

    func updateProjectiles(_ dt: CGFloat) {
        var toRemove: [Int] = []
        for i in 0..<projectiles.count {
            projectiles[i].life -= dt
            projectiles[i].node.position.x += projectiles[i].vel.x * dt
            projectiles[i].node.position.y += projectiles[i].vel.y * dt
            // Spin the bone
            projectiles[i].node.zRotation += 12 * dt

            let p = projectiles[i].node.position
            // Hit player?
            let dx = p.x - pPos.x
            let dy = p.y - (pPos.y + PH/2)
            if sqrt(dx*dx + dy*dy) < 28 {
                damagePlayer(1, from: p)
                toRemove.append(i)
                continue
            }
            // Hit wall?
            if isSolid(p.x, p.y) {
                toRemove.append(i)
                continue
            }
            // Expired?
            if projectiles[i].life <= 0 {
                toRemove.append(i)
            }
        }
        for i in toRemove.reversed() {
            projectiles[i].node.removeFromParent()
            projectiles.remove(at: i)
        }
    }

    func checkExit() {
        let dx = pPos.x - exitPos.x
        let dy = pPos.y - exitPos.y
        if abs(dx) < TS && abs(dy) < TS { nextFloor() }
    }

    // ── Camera ──
    func updateCamera() {
        if state == "playing" {
            let tx = pPos.x; let ty = pPos.y + 60
            cam.position.x += (tx - cam.position.x) * 0.08
            cam.position.y += (ty - cam.position.y) * 0.08
            // Clamp
            let lw = CGFloat(LEVEL_COLS) * TS
            let lh = CGFloat(LEVEL_ROWS) * TS
            cam.position.x = max(WIN_W/2, min(lw - WIN_W/2, cam.position.x))
            cam.position.y = max(WIN_H/2, min(lh - WIN_H/2, cam.position.y))
        }
        // Shake
        if shakeAmt > 0.5 {
            cam.position.x += CGFloat.random(in: -shakeAmt...shakeAmt)
            cam.position.y += CGFloat.random(in: -shakeAmt...shakeAmt)
        }
        // Parallax: bg scrolls slower
        let dx = cam.position.x - WIN_W/2
        bgNode.position.x = -dx * 0.3
    }

    // ── HUD ──
    func updateHUD() {
        let pct = CGFloat(pHP) / CGFloat(pMaxHP)
        hudHP.xScale = max(0.01, pct)
        hudHP.fillColor = pct > 0.5 ? rgb(50,200,80) : (pct > 0.25 ? rgb(220,180,30) : rgb(200,40,40))
        hudFloor.text = "FLOOR \(floorNum)"
        hudKills.text = "KILLS: \(kills)"
    }
}

// ══════════════════════════════════════════════════════════════
// MARK: - APP
// ══════════════════════════════════════════════════════════════
class GameView: SKView {
    override var acceptsFirstResponder: Bool { true }
    // Prevent system from eating arrow keys for navigation
    override func performKeyEquivalent(with event: NSEvent) -> Bool { return false }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    func applicationDidFinishLaunching(_ n: Notification) {
        let rect = NSRect(x: 0, y: 0, width: WIN_W, height: WIN_H)
        window = NSWindow(contentRect: rect,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered, defer: false)
        window.title = "Crypts of Shadow"
        window.center()
        window.backgroundColor = NSColor.black

        let v = GameView(frame: rect)
        v.ignoresSiblingOrder = true
        window.contentView = v

        let scene = DungeonScene(size: CGSize(width: WIN_W, height: WIN_H))
        scene.scaleMode = .aspectFit
        v.presentScene(scene)

        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(v)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { true }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.activate(ignoringOtherApps: true)
app.run()
