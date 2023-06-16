## Greenplum にデータを書き込み、セグメントホストに分散されることを確認するデモ (セグメントホスト2 つ以上必要)

### テーブルの作成（DISTRIBUTED BY が未指定の場合PRIMARY KEY で分散）
```sql
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(50),
    price DECIMAL(10, 2),
    category VARCHAR(50)
);

INSERT INTO products (product_id, product_name, price, category)
VALUES 
    (1, 'りんご', 150, '果物'),
    (2, 'バナナ', 100, '果物'),
    (3, 'みかん', 200, '果物'),
    (4, 'メロン', 1000, '果物'),
    (5, 'キャベツ', 200, '野菜'),
    (6, '牛肉', 200, '肉');
```
### テーブルの表示
```sql
SELECT * FROM products;
```

### セグメントホスト配置の確認
```sql
SELECT gp_segment_id, product_id, product_name, price, category
FROM products;
```

### テーブルの削除
```sql
DROP TABLE products;
```

### 次にカテゴリで分散させる
```sql
CREATE TABLE products (
    product_id INT,
    product_name VARCHAR(50),
    price DECIMAL(10,2),
    category VARCHAR(50)
) DISTRIBUTED BY (category);

INSERT INTO products (product_id, product_name, price, category)
VALUES 
    (1, 'りんご', 150, '果物'),
    (2, 'バナナ', 100, '果物'),
    (3, 'みかん', 200, '果物'),
    (4, 'メロン', 1000, '果物'),
    (5, 'キャベツ', 200, '野菜'),
    (6, '牛肉', 200, '肉');
```
### セグメントホスト配置の確認
```sql
SELECT gp_segment_id, product_id, product_name, price, category
FROM products;
```
### テーブルの削除
```sql
DROP TABLE products;
```
