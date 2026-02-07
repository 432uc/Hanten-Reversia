using UnityEngine;

// 駒（カード）のデータと状態を管理するクラス
public class Piece : MonoBehaviour
{
    [Header("Basic Info")]
    public int id;
    public new string name; // 駒の名前
    public int attackPower; // 基本攻撃力 (ATK)
    public int attribute;   // 属性 (0: None, 1: Fire, 2: Water, etc... 今はintで管理)

    [Header("State")]
    public int owner; // 0: None, 1: Player1, 2: Player2

    // 駒の初期化用メソッド
    public void Initialize(int id, string name, int atk, int attr, int ownerId)
    {
        this.id = id;
        this.name = name;
        this.attackPower = atk;
        this.attribute = attr;
        this.owner = ownerId;
    }

    // 所有者を変更する（オセロで裏返る時の処理）
    public void SetOwner(int newOwnerId)
    {
        this.owner = newOwnerId;
        
        // 視覚的な色変更などをここに入れる（プロトタイプ用にログだけ出す）
        Debug.Log($"{name} changed owner to Player {newOwnerId}");
        
        // 簡単な色変えの実装例（MeshRendererなどがある場合）
        // GetComponent<Renderer>().material.color = (newOwnerId == 1) ? Color.black : Color.white;
    }
}
