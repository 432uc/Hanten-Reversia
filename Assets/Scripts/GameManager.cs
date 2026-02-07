using UnityEngine;

// ゲームの進行管理（ターン、HP、勝敗）を行うクラス
public class GameManager : MonoBehaviour
{
    [Header("Game Settings")]
    public int maxHP = 1000;
    public float comboMultiplier = 0.5f; // ダメージ係数 (例: 1枚につき50%アップ)

    [Header("References")]
    public Board board;
    public Piece defaultPiecePrefab; // 初期配置用の駒プレハブ

    // 現在のゲーム状態
    private int currentPlayer = 1; // 1: Player1, 2: Player2
    private int hpP1;
    private int hpP2;
    private bool isGameActive = false;

    // 定数: 盤面サイズ
    private const int BOARD_SIZE = 6;

    void Start()
    {
        // テスト用に起動時に開始（実際はUIボタンなどで呼ぶ）
        StartGame();
    }

    // ゲーム開始処理
    public void StartGame()
    {
        hpP1 = maxHP;
        hpP2 = maxHP;
        currentPlayer = 1;
        isGameActive = true;
        
        board.InitializeBoard();
        
        // 初期配置 (オセロの定石: 中央に4つ配置)
        // 6x6の場合、中心は (2,2), (2,3), (3,2), (3,3)
        // P1: (2,3), (3,2) / P2: (2,2), (3,3) ※配置パターンは一例
        SetupInitialPiece(2, 2, 2);
        SetupInitialPiece(3, 3, 2);
        SetupInitialPiece(2, 3, 1);
        SetupInitialPiece(3, 2, 1);
        
        Debug.Log("Game Started. Player 1's Turn.");
    }

    // 初期配置用のヘルパー
    private void SetupInitialPiece(int x, int y, int owner)
    {
        if (defaultPiecePrefab != null)
        {
            Piece p = Instantiate(defaultPiecePrefab);
            // 仮のパラメータで初期化
            p.Initialize(0, "Pawn", 10, 0, owner); 
            
            // 座標調整 (盤面のスケールに合わせて調整が必要)
            p.transform.position = new Vector3(x, 0, y); 
            
            board.PlacePieceOnGrid(x, y, p);
        }
        else
        {
            Debug.LogError("Default Piece Prefab is not assigned in GameManager!");
        }
    }

    // プレイヤーが駒を置こうとする処理
    // UIやInputManagerからクリックされた座標と、使用するカード(Piece)を受け取る想定
    public void TryPlacePiece(int x, int y, Piece piecePrefab)
    {
        if (!isGameActive)
        {
            Debug.Log("Game is over.");
            return;
        }

        // 指定座標に置けるかチェック
        if (board.CanPlace(x, y, currentPlayer))
        {
            // 置ける場合
            // 1. 駒を生成して配置
            Piece newPiece = Instantiate(piecePrefab);
            // プレハブのデータを使って初期化（所有者は現在のプレイヤー）
            newPiece.Initialize(piecePrefab.id, piecePrefab.name, piecePrefab.attackPower, piecePrefab.attribute, currentPlayer);
            
            // 座標更新 (とりあえず X, Z平面とする)
            newPiece.transform.position = new Vector3(x, 0, y); 

            // 2. 盤面に登録
            board.PlacePieceOnGrid(x, y, newPiece);

            // 3. 裏返る駒を取得して裏返す
            var flippedPieces = board.GetFlippablePieces(x, y, currentPlayer);
            foreach (var p in flippedPieces)
            {
                p.SetOwner(currentPlayer);
                // 裏返るアニメーションがあればここで再生
            }

            // 4. ダメージ計算と適用
            int damage = CalculateDamage(newPiece, flippedPieces.Count);
            ApplyDamage(damage);

            // 5. 勝利判定
            if (CheckWinCondition())
            {
                isGameActive = false;
                Debug.Log($"Player {currentPlayer} Wins!");
            }
            else
            {
                // 6. ターン交代
                SwitchTurn();
            }
        }
        else
        {
            Debug.Log($"Cannot place piece at ({x},{y}). No flippable pieces or occupied.");
        }
    }

    // ダメージ計算ロジック
    // 式: 基本攻撃力 * (1 + 裏返した枚数 * 係数)
    private int CalculateDamage(Piece attacker, int flippedCount)
    {
        // 係数計算
        float multiplier = 1.0f + (flippedCount * comboMultiplier);
        
        // ダメージ算出
        int totalDamage = Mathf.FloorToInt(attacker.attackPower * multiplier);
        
        // ※ ここにスキル処理を記述 ※
        // 例: if (attacker.id == 10) { totalDamage += 50; }
        
        Debug.Log($"Damage Calc: ATK {attacker.attackPower} * (1 + {flippedCount} flips * {comboMultiplier}) = {totalDamage}");
        
        return totalDamage;
    }

    // ダメージ適用
    private void ApplyDamage(int damage)
    {
        if (currentPlayer == 1)
        {
            hpP2 -= damage;
            Debug.Log($"Player 1 deals {damage} damage! -> Player 2 HP: {hpP2}");
        }
        else
        {
            hpP1 -= damage;
            Debug.Log($"Player 2 deals {damage} damage! -> Player 1 HP: {hpP1}");
        }
    }

    // 勝利条件チェック
    private bool CheckWinCondition()
    {
        if (hpP1 <= 0) return true;
        if (hpP2 <= 0) return true;
        return false;
    }

    // ターン交代
    private void SwitchTurn()
    {
        currentPlayer = (currentPlayer == 1) ? 2 : 1;
        Debug.Log($"=== Player {currentPlayer}'s Turn ===");

        // 発展課題: パス判定（どこにも置けない場合）の実装が必要
        // if (!HasValidMove(currentPlayer)) SwitchTurn();
    }
}
