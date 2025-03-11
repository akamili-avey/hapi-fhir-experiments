Observations about indexing made that is not documented in the tests

I verified that sorting by age is using indexed query on the table [hfj_spidx_number](https://hapifhir.io/hapi-fhir/docs/server_jpa/schema.html#hfj-spidx-number-number-search-parameters).

With the expunge step commented, I ran the following request after `./test.sh`:
```
GET http://localhost:8080/fhir/Patient?age=ge23
```

And enabled logging for postgres, I got the following logs:
```
2025-03-11 07:08:57 GMT [34]: <truncated> LOG:  execute S_11: BEGIN
2025-03-11 07:08:57 GMT [34]: <truncated> LOG:  duration: 0.009 ms
2025-03-11 07:08:57 GMT [34]: <truncated> LOG:  duration: 0.327 ms  parse <unnamed>: SELECT t0.RES_ID FROM HFJ_SPIDX_NUMBER t0 WHERE ((t0.HASH_IDENTITY = $1) AND (t0.SP_VALUE >= $2)) fetch first $3 rows only
2025-03-11 07:08:57 GMT [34]: <truncated> LOG:  duration: 0.207 ms  bind <unnamed>/C_48: SELECT t0.RES_ID FROM HFJ_SPIDX_NUMBER t0 WHERE ((t0.HASH_IDENTITY = $1) AND (t0.SP_VALUE >= $2)) fetch first $3 rows only
2025-03-11 07:08:57 GMT [34]: <truncated> DETAIL:  parameters: $1 = '-2889248177859195071', $2 = '23', $3 = '21'
2025-03-11 07:08:57 GMT [34]: <truncated> LOG:  execute <unnamed>/C_48: SELECT t0.RES_ID FROM HFJ_SPIDX_NUMBER t0 WHERE ((t0.HASH_IDENTITY = $1) AND (t0.SP_VALUE >= $2)) fetch first $3 rows only
2025-03-11 07:08:57 GMT [34]: <truncated> DETAIL:  parameters: $1 = '-2889248177859195071', $2 = '23', $3 = '21'
2025-03-11 07:08:57 GMT [34]: <truncated> LOG:  duration: 0.142 ms
```

Translating it into a query plan gives the following:
```
hapi=# EXPLAIN ANALYZE SELECT t0.RES_ID
FROM HFJ_SPIDX_NUMBER t0
WHERE (t0.HASH_IDENTITY = -2889248177859195071)
  AND (t0.SP_VALUE >= 23)
FETCH FIRST 21 ROWS ONLY;

QUERY PLAN
---------------------------------------------------------------------------------------------------------
 Limit  (cost=0.14..2.36 rows=1 width=8) (actual time=0.252..0.256 rows=2 loops=1)
   ->  Index Only Scan using idx_sp_number_hash_val_v2 on hfj_spidx_number t0  (cost=0.14..2.36 rows=1 width=8) (actual time=0.250..0.252 rows=2 loops=1)
         Index Cond: ((hash_identity = '-2889248177859195071'::bigint) AND (sp_value >= '23'::numeric))
         Heap Fetches: 2
Planning Time: 0.549 ms
Execution Time: 0.364 ms
(6 rows)
```

