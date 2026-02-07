import 'package:flutter/material.dart';

// アプリのエントリーポイント
void main() {
  runApp(const OthelloRpgApp());
}

// ------------------------------------------------------------
// データ・ロジック層 (Model & Logic)
// ------------------------------------------------------------

enum Attribute { fire, water, wind, earth }

/// 駒（カード/キャラクター）のデータ定義
class Piece {
  final int id;
  final String name;
  final int attack; // 基本攻撃力
  final Attribute attribute;
  final IconData icon; // 簡易表示用のアイコン

  Piece({
    required this.id,
    required this.name,
    required this.attack,
    required this.attribute,
    required this.icon,
  });
}

/// オセロの盤面ロジックとゲーム状態管理
class OthelloLogic {
  // 盤面サイズ: 6x6
  static const int boardSize = 6;
  
  // 盤面データ: nullなら空き、Pieceならその駒が置かれている
  // ただし「誰の駒か」を管理する必要があるため、少し構造を変えるか、
  // Piece自体に所有者を持たせるか。ここではシンプルに「グリッド上の駒情報」クラスを作る。
  final List<List<PlacedPiece?>> board;

  // プレイヤーID (1: 先攻(黒/赤), 2: 後攻(白/青))
  int currentPlayer = 1;

  // 各プレイヤーのHP
  int hpPlayer1 = 1000;
  int hpPlayer2 = 1000;

  // ゲーム終了フラグ
  bool isGameOver = false;
  String? winnerMessage;

  OthelloLogic()
      : board = List.generate(
          boardSize,
          (_) => List.generate(boardSize, (_) => null),
        ) {
    _initializeBoard();
  }

  // 初期配置: 中央4つに配置する（オセロルール）
  // 今回はテスト用にデフォルトの弱い駒を置く
  void _initializeBoard() {
    // 6x6の中央は (2,2), (2,3), (3,2), (3,3)
    // プレイヤー1: (2,3), (3,2)
    // プレイヤー2: (2,2), (3,3)
    var p1Piece = Piece(id: 0, name: "Pawn", attack: 10, attribute: Attribute.fire, icon: Icons.local_fire_department);
    var p2Piece = Piece(id: 0, name: "Pawn", attack: 10, attribute: Attribute.water, icon: Icons.water_drop);

    board[2][2] = PlacedPiece(owner: 2, pieceData: p2Piece);
    board[3][3] = PlacedPiece(owner: 2, pieceData: p2Piece);
    board[2][3] = PlacedPiece(owner: 1, pieceData: p1Piece);
    board[3][2] = PlacedPiece(owner: 1, pieceData: p1Piece);
  }

  // 指定マスに置けるか判定し、置けるなら裏返るリストを返す
  List<Point> getFlippablePoints(int x, int y, int player) {
    if (board[y][x] != null) return []; // 既に駒がある

    List<Point> flippablePoints = [];
    
    // 8方向の定義
    final directions = [
      const Point(0, -1), const Point(1, -1), const Point(1, 0),
      const Point(1, 1), const Point(0, 1), const Point(-1, 1),
      const Point(-1, 0), const Point(-1, -1),
    ];

    for (var dir in directions) {
      List<Point> tempPoints = [];
      int currentX = x + dir.x;
      int currentY = y + dir.y;

      while (isValid(currentX, currentY)) {
        final target = board[currentY][currentX];
        if (target == null) break; // 空きマスなら終了

        if (target.owner != player) {
          // 相手の駒ならリスト候補に追加
          tempPoints.add(Point(currentX, currentY));
        } else {
          // 自分の駒に到達したら、挟めたことになる
          if (tempPoints.isNotEmpty) {
            flippablePoints.addAll(tempPoints);
          }
          break;
        }

        currentX += dir.x;
        currentY += dir.y;
      }
    }

    return flippablePoints;
  }

  // 駒を置く（ダメージ計算含む）
  // 戻り値: {damage: ダメージ値, flippedCount: 裏返した枚数, success: 成功可否}
  Map<String, dynamic> placePiece(int x, int y, Piece piece) {
    if (isGameOver) return {'success': false};

    var flippables = getFlippablePoints(x, y, currentPlayer);
    if (flippables.isEmpty) {
      return {'success': false}; // ルール上置けない
    }

    // 1. 駒を置く
    board[y][x] = PlacedPiece(owner: currentPlayer, pieceData: piece);

    // 2. 挟んだ駒を裏返す（所有権を変更）
    for (var p in flippables) {
      // 実際には駒データはそのままで所有者だけ変えるのか、
      // 駒が「攻撃した側の属性」に染まるイメージでデータごと変えるかは仕様次第。
      // ここではシンプルに「所有者だけ変更」する（オセロ的）
      board[p.y][p.x]!.owner = currentPlayer;
    }

    // 3. ダメージ計算
    // 式: 基本攻撃力 * 裏返した枚数
    // （オプションとしてコンボボーナスなどを入れるならここ）
    int damage = piece.attack * flippables.length;
    
    // 相手へのダメージ適用
    if (currentPlayer == 1) {
      hpPlayer2 -= damage;
    } else {
      hpPlayer1 -= damage;
    }

    // 4. 勝敗判定
    if (hpPlayer1 <= 0 || hpPlayer2 <= 0) {
      isGameOver = true;
      winnerMessage = (hpPlayer1 > hpPlayer2) ? "Player 1 Wins!" : "Player 2 Wins!";
    } else {
      // 5. ターン交代
      // パス判定は省略（簡易実装のため、置ける場所がなくても交代する）
      currentPlayer = (currentPlayer == 1) ? 2 : 1;
    }

    return {
      'success': true,
      'damage': damage,
      'flippedCount': flippables.length,
    };
  }

  bool isValid(int x, int y) {
    return x >= 0 && x < boardSize && y >= 0 && y < boardSize;
  }
}

// 座標クラス
class Point {
  final int x;
  final int y;
  const Point(this.x, this.y);
}

// 盤面に置かれている駒の状態
class PlacedPiece {
  int owner; // 1 or 2
  final Piece pieceData;
  PlacedPiece({required this.owner, required this.pieceData});
}


// ------------------------------------------------------------
// プレゼンテーション層 (UI)
// ------------------------------------------------------------

class OthelloRpgApp extends StatelessWidget {
  const OthelloRpgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Othello RPG',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late OthelloLogic logic;
  // 選択中の手駒（今は1種類固定だが、本来はデッキから選ぶ）
  // プレイヤー1用
  final Piece p1SelectedPiece = Piece(id: 1, name: "Warrior", attack: 150, attribute: Attribute.fire, icon: Icons.whatshot);
  // プレイヤー2用
  final Piece p2SelectedPiece = Piece(id: 2, name: "Mage", attack: 120, attribute: Attribute.water, icon: Icons.ac_unit);

  @override
  void initState() {
    super.initState();
    logic = OthelloLogic();
  }

  // リセット
  void _resetGame() {
    setState(() {
      logic = OthelloLogic();
    });
  }

  // タップ時の処理
  void _onCellTap(int x, int y) {
    if (logic.isGameOver) return;

    // 現在のプレイヤーに応じた駒を使用
    Piece currentPiece = (logic.currentPlayer == 1) ? p1SelectedPiece : p2SelectedPiece;

    var result = logic.placePiece(x, y, currentPiece);
    if (result['success']) {
      setState(() {
        // 画面更新
      });
      
      // ダメージ表示などの演出（スナックバーで簡易表示）
      int dmg = result['damage'];
      int count = result['flippedCount'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Combo x$count! Deal $dmg Damage!"),
          duration: const Duration(milliseconds: 800),
        ),
      );

      if (logic.isGameOver) {
        _showGameOverDialog(logic.winnerMessage ?? "Draw");
      }
    } else {
      // 置けない場合
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cannot place here!"),
          duration: Duration(milliseconds: 500),
        ),
      );
    }
  }

  void _showGameOverDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Game Set"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            child: const Text("Restart"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Othello RPG Prototype"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
          )
        ],
      ),
      body: Column(
        children: [
          // 1. HPバーとターン情報
          _buildStatusArea(),

          // 2. 盤面
          Expanded(
            child: _buildBoard(context),
          ),

          // 3. 手駒情報（簡易版）
          _buildHandArea(),
        ],
      ),
    );
  }

  Widget _buildStatusArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[900],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPlayerStatus(
                "Player 1 (Red)", 
                logic.hpPlayer1, 
                logic.currentPlayer == 1,
                Colors.redAccent
              ),
              const Text("VS", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              _buildPlayerStatus(
                "Player 2 (Blue)", 
                logic.hpPlayer2, 
                logic.currentPlayer == 2,
                Colors.blueAccent
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            logic.isGameOver ? "GAME OVER" : "Turn: Player ${logic.currentPlayer}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerStatus(String name, int hp, bool isTurn, Color color) {
    return Column(
      children: [
        Text(name, style: TextStyle(color: color, fontWeight: isTurn ? FontWeight.bold : FontWeight.normal)),
        Text(
          "HP: $hp", 
          style: TextStyle(
            fontSize: 24, 
            color: (hp <= 0) ? Colors.grey : Colors.white,
            fontWeight: FontWeight.bold
          )
        ),
        if (isTurn) 
          Container(height: 4, width: 60, color: color, margin: const EdgeInsets.only(top: 4))
      ],
    );
  }

  Widget _buildBoard(BuildContext context) {
    final gridSize = OthelloLogic.boardSize;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.brown[800], // 盤の枠色
              borderRadius: BorderRadius.circular(8),
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: gridSize * gridSize,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridSize,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemBuilder: (context, index) {
                final x = index % gridSize;
                final y = index ~/ gridSize;
                final piece = logic.board[y][x];

                // 置ける場所のヒント表示用（自分のターンなら計算して表示）
                bool isHint = false;
                if (!logic.isGameOver && piece == null) {
                  isHint = logic.getFlippablePoints(x, y, logic.currentPlayer).isNotEmpty;
                }

                return GestureDetector(
                  onTap: () => _onCellTap(x, y),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green[700], // マスの色
                      border: isHint 
                        ? Border.all(color: Colors.yellowAccent.withAlpha(150), width: 2) 
                        : null,
                    ),
                    child: Center(
                      child: piece != null 
                        ? _buildPieceWidget(piece)
                        : (isHint ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white30, shape: BoxShape.circle)) : null),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPieceWidget(PlacedPiece placedPiece) {
    final color = (placedPiece.owner == 1) ? Colors.red : Colors.blue;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black45, offset: Offset(2, 2), blurRadius: 2)
        ]
      ),
      child: Icon(placedPiece.pieceData.icon, color: Colors.white, size: 24),
    );
  }

  Widget _buildHandArea() {
    // 簡易的に「今この駒を使ってます」を表示
    final currentPiece = (logic.currentPlayer == 1) ? p1SelectedPiece : p2SelectedPiece;
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[850],
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Using: "),
          Icon(currentPiece.icon),
          const SizedBox(width: 8),
          Text("${currentPiece.name} (ATK: ${currentPiece.attack})", style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
