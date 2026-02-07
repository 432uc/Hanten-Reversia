using UnityEngine;
using System.Collections.Generic;

// 盤面管理クラス。グリッドの状態と配置判定を行う
public class Board : MonoBehaviour
{
    // 6x6のグリッド
    // 各セルにどの駒が置かれているかを管理する
    private Piece[,] grid = new Piece[6, 6];

    // 方向チェック用のオフセット
    // 左上, 上, 右上, 左, 右, 左下, 下, 右下
    private Vector2Int[] checkDirections = new Vector2Int[]
    {
        new Vector2Int(-1, -1), new Vector2Int(0, -1), new Vector2Int(1, -1),
        new Vector2Int(-1, 0),                         new Vector2Int(1, 0),
        new Vector2Int(-1, 1),  new Vector2Int(0, 1),  new Vector2Int(1, 1)
    };

    // 初期化
    public void InitializeBoard()
    {
        // グリッドをクリア
        for(int x = 0; x < 6; x++)
        {
            for(int y = 0; y < 6; y++)
            {
                grid[x, y] = null;
            }
        }
    }

    // 指定座標に駒を置く
    public void PlacePieceOnGrid(int x, int y, Piece piece)
    {
        if (IsValidCoord(x, y))
        {
            grid[x, y] = piece;
        }
        else
        {
            Debug.LogError($"Invalid coordinate: {x}, {y}");
        }
    }

    // 座標にある駒を取得
    public Piece GetPieceAt(int x, int y)
    {
        if (IsValidCoord(x, y))
        {
            return grid[x, y];
        }
        return null;
    }

    // 座標が盤面内かチェック
    private bool IsValidCoord(int x, int y)
    {
        return x >= 0 && x < 6 && y >= 0 && y < 6;
    }

    // 指定した座標にプレイヤー(playerSide)が駒を置けるか判定
    public bool CanPlace(int x, int y, int playerSide)
    {
        // 既に駒があるなら置けない
        if (grid[x, y] != null) return false;

        // 裏返せる駒が1つ以上あるなら置ける
        List<Piece> flippables = GetFlippablePieces(x, y, playerSide);
        return flippables.Count > 0;
    }

    // 指定座標に置いた場合に裏返る駒のリストを取得する
    // playerSide: 置こうとしているプレイヤー (1:Player1, 2:Player2)
    public List<Piece> GetFlippablePieces(int startX, int startY, int playerSide)
    {
        List<Piece> piecesToFlip = new List<Piece>();

        // 全8方向をチェック
        foreach (var dir in checkDirections)
        {
            List<Piece> potentialFlips = new List<Piece>();
            int currentX = startX + dir.x;
            int currentY = startY + dir.y;

            while (IsValidCoord(currentX, currentY))
            {
                Piece p = grid[currentX, currentY];

                // 何もないマスに当たったら、この方向では挟めない
                if (p == null) break;

                // 自分の駒に当たったら、間にあった相手の駒を確定リストに入れる
                if (p.owner == playerSide)
                {
                    piecesToFlip.AddRange(potentialFlips);
                    break;
                }
                else
                {
                    // 相手の駒なら裏返り候補としてリストに追加して次へ
                    potentialFlips.Add(p);
                }

                currentX += dir.x;
                currentY += dir.y;
            }
        }

        return piecesToFlip;
    }
}
