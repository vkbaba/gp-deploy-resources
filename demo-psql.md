## Greenplum にデータを書き込み、セグメントに分散されることを確認するデモ 
セグメントは2 つ以上必要

### ログイン
マスターにgpadmin でログイン後に下記を実行
```
psql postgres
```
### テーブルの作成
DISTRIBUTED BY が未指定の場合PRIMARY KEY でデータが分散
```sql
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(50),
    price DECIMAL(10, 2),
    category VARCHAR(50)
);

```

### データの作成
```sql
INSERT INTO products (product_id, product_name, price, category) 
VALUES (1, 'りんご', 150, '果物'), 
(2, 'バナナ', 100, '果物'), 
(3, 'みかん', 200, '果物'), 
(4, 'ピーマン', 100, '野菜'), 
(5, 'キャベツ', 200, '野菜'), 
(6, 'トイレットペーパー', 300, '日用品'), 
(7, 'メロン', 1000, '果物'), 
(8, '洗剤', 200, '日用品'), 
(9, 'もやし', 30, '野菜'), 
(10, 'ごみ袋', 200, '日用品');
```

### テーブルの表示
```sql
SELECT * FROM products;
```
```
postgres=# SELECT * FROM products;
 product_id |    product_name    |  price  | category
------------+--------------------+---------+----------
          1 | りんご             |  150.00 | 果物
          5 | キャベツ           |  200.00 | 野菜
          6 | トイレットペーパー |  300.00 | 日用品
          9 | もやし             |   30.00 | 野菜
         10 | ごみ袋             |  200.00 | 日用品
          2 | バナナ             |  100.00 | 果物
          3 | みかん             |  200.00 | 果物
          4 | ピーマン           |  100.00 | 野菜
          7 | メロン             | 1000.00 | 果物
          8 | 洗剤               |  200.00 | 日用品
(10 rows)
```
### セグメントホスト配置の確認
```sql
SELECT gp_segment_id, product_id, product_name, price, category
FROM products;
```
```
postgres=# SELECT gp_segment_id, product_id, product_name, price, category
postgres-# FROM products;
 gp_segment_id | product_id |    product_name    |  price  | category
---------------+------------+--------------------+---------+----------
             2 |          5 | キャベツ           |  200.00 | 野菜
             2 |          6 | トイレットペーパー |  300.00 | 日用品
             2 |          9 | もやし             |   30.00 | 野菜
             2 |         10 | ごみ袋             |  200.00 | 日用品
             0 |          2 | バナナ             |  100.00 | 果物
             0 |          3 | みかん             |  200.00 | 果物
             0 |          4 | ピーマン           |  100.00 | 野菜
             0 |          7 | メロン             | 1000.00 | 果物
             0 |          8 | 洗剤               |  200.00 | 日用品
             1 |          1 | りんご             |  150.00 | 果物
(10 rows)

```
gp_segment_id によってどのセグメントに配置されているかが確認可能

### テーブルの削除
```sql
DROP TABLE products;
```

### テーブルの作成
カテゴリでデータを分散させる
```sql
CREATE TABLE products (
    product_id INT,
    product_name VARCHAR(50),
    price DECIMAL(10,2),
    category VARCHAR(50)
) DISTRIBUTED BY (category);
```

```sql
INSERT INTO products (product_id, product_name, price, category) 
VALUES (1, 'りんご', 150, '果物'), 
(2, 'バナナ', 100, '果物'), 
(3, 'みかん', 200, '果物'), 
(4, 'ピーマン', 100, '野菜'), 
(5, 'キャベツ', 200, '野菜'), 
(6, 'トイレットペーパー', 300, '日用品'), 
(7, 'メロン', 1000, '果物'), 
(8, '洗剤', 200, '日用品'), 
(9, 'もやし', 30, '野菜'), 
(10, 'ごみ袋', 200, '日用品');
```

### セグメントホスト配置の確認
```sql
SELECT gp_segment_id, product_id, product_name, price, category
FROM products;
```

```
postgres=# SELECT gp_segment_id, product_id, product_name, price, category
postgres-# FROM products;
 gp_segment_id | product_id |    product_name    |  price  | category
---------------+------------+--------------------+---------+----------
             2 |          4 | ピーマン           |  100.00 | 野菜
             2 |          5 | キャベツ           |  200.00 | 野菜
             2 |          9 | もやし             |   30.00 | 野菜
             1 |          6 | トイレットペーパー |  300.00 | 日用品
             1 |          8 | 洗剤               |  200.00 | 日用品
             1 |         10 | ごみ袋             |  200.00 | 日用品
             0 |          1 | りんご             |  150.00 | 果物
             0 |          2 | バナナ             |  100.00 | 果物
             0 |          3 | みかん             |  200.00 | 果物
             0 |          7 | メロン             | 1000.00 | 果物
(10 rows)
```
カテゴリごとにgp_segment_id が同じ=カテゴリごとにデータを分散

### テーブルの削除
```sql
DROP TABLE products;
```
