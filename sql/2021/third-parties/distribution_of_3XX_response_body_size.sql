#standardSQL
# Distribution of response body size by redirected third parties
# HTTP status codes documentation: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status

WITH requests AS (
  SELECT
    _TABLE_SUFFIX AS client,
    url,
    status,
    respBodySize AS body_size
  FROM
    `httparchive.summary_requests.2021_07_01_*`
),

third_party AS (
  SELECT
    domain
  FROM
    `httparchive.almanac.third_parties`
  WHERE
    date = '2021-07-01' AND
    category != 'hosting'
),

base AS (
  SELECT
    client,
    domain,
    IF(status BETWEEN 300 AND 399, 1, 0) AS redirected,
    body_size
  FROM
    requests
  LEFT JOIN
    third_party
  ON
    NET.HOST(requests.url) = NET.HOST(third_party.domain)
)

SELECT
  client,
  percentile,
  APPROX_QUANTILES(body_size, 1000)[OFFSET(percentile * 10)] AS approx_redirect_body_size
FROM
  base,
  UNNEST(GENERATE_ARRAY(1, 100)) AS percentile
WHERE
  redirected = 1
GROUP BY
  client,
  percentile
ORDER BY
  client,
  percentile