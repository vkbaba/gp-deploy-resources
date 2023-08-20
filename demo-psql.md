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

```
postgres=# CREATE TABLE products (
postgres(#     product_id INT PRIMARY KEY,
postgres(#     product_name VARCHAR(50),
postgres(#     price DECIMAL(10, 2),
postgres(#     category VARCHAR(50)
postgres(# );
CREATE TABLE
```
### データの作成
```sql
INSERT INTO products (product_id, product_name, price, category)
VALUES 
    (1, 'りんご', 150, '果物'),
    (2, 'バナナ', 100, '果物'),
    (3, 'みかん', 200, '果物'),
    (4, 'メロン', 1000, '果物'),
    (5, 'キャベツ', 200, '野菜'),
    (6, '牛肉', 200, '肉');
```

```
postgres=# INSERT INTO products (product_id, product_name, price, category)
postgres-# VALUES
postgres-#     (1, 'りんご', 150, '果物'),
postgres-#     (2, 'バナナ', 100, '果物'),
postgres-#     (3, 'みかん', 200, '果物'),
postgres-#     (4, 'メロン', 1000, '果物'),
postgres-#     (5, 'キャベツ', 200, '野菜'),
postgres-#     (6, '牛肉', 200, '肉');
INSERT 0 6
```
### テーブルの表示
```sql
SELECT * FROM products;
```
```
postgres=# SELECT * FROM products;
 product_id | product_name |  price  | category
------------+--------------+---------+----------
          1 | りんご       |  150.00 | 果物
          5 | キャベツ     |  200.00 | 野菜
          2 | バナナ       |  100.00 | 果物
          3 | みかん       |  200.00 | 果物
          4 | メロン       | 1000.00 | 果物
          6 | 牛肉         |  200.00 | 肉
(6 rows)
```
### セグメントホスト配置の確認
```sql
SELECT gp_segment_id, product_id, product_name, price, category
FROM products;
```
```
postgres=# SELECT gp_segment_id, product_id, product_name, price, category
postgres-# FROM products;
 gp_segment_id | product_id | product_name |  price  | category
---------------+------------+--------------+---------+----------
             0 |          2 | バナナ       |  100.00 | 果物
             0 |          3 | みかん       |  200.00 | 果物
             0 |          4 | メロン       | 1000.00 | 果物
             0 |          6 | 牛肉         |  200.00 | 肉
             1 |          1 | りんご       |  150.00 | 果物
             1 |          5 | キャベツ     |  200.00 | 野菜
(6 rows)
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

```
postgres=# CREATE TABLE products (
postgres(#     product_id INT,
postgres(#     product_name VARCHAR(50),
postgres(#     price DECIMAL(10,2),
postgres(#     category VARCHAR(50)
postgres(# ) DISTRIBUTED BY (category);
CREATE TABLE
```

```sql
INSERT INTO products (product_id, product_name, price, category)
VALUES 
    (1, 'りんご', 150, '果物'),
    (2, 'バナナ', 100, '果物'),
    (3, 'みかん', 200, '果物'),
    (4, 'メロン', 1000, '果物'),
    (5, 'キャベツ', 200, '野菜'),
    (6, '牛肉', 200, '肉');
```
```
postgres=# INSERT INTO products (product_id, product_name, price, category)
postgres-# VALUES
postgres-#     (1, 'りんご', 150, '果物'),
postgres-#     (2, 'バナナ', 100, '果物'),
postgres-#     (3, 'みかん', 200, '果物'),
postgres-#     (4, 'メロン', 1000, '果物'),
postgres-#     (5, 'キャベツ', 200, '野菜'),
postgres-#     (6, '牛肉', 200, '肉');
INSERT 0 6
```
### セグメントホスト配置の確認
```sql
SELECT gp_segment_id, product_id, product_name, price, category
FROM products;
```

```
postgres=# SELECT gp_segment_id, product_id, product_name, price, category
postgres-# FROM products;
 gp_segment_id | product_id | product_name |  price  | category
---------------+------------+--------------+---------+----------
             0 |          1 | りんご       |  150.00 | 果物
             0 |          2 | バナナ       |  100.00 | 果物
             0 |          3 | みかん       |  200.00 | 果物
             0 |          4 | メロン       | 1000.00 | 果物
             0 |          5 | キャベツ     |  200.00 | 野菜
             1 |          6 | 牛肉         |  200.00 | 肉
(6 rows)
```
果物カテゴリのデータはgp_segment_id が同じ=カテゴリごとにデータを分散

### テーブルの削除
```sql
DROP TABLE products;
```
