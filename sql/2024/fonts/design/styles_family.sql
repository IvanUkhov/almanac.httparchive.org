-- Section: Design
-- Question: Which families are popular?

CREATE TEMPORARY FUNCTION FAMILIES(json STRING)
RETURNS ARRAY<STRING>
LANGUAGE js
OPTIONS (library = ["gs://httparchive/lib/css-font-parser.js", "gs://httparchive/lib/css-utils.js"])
AS '''
try {
  const $ = JSON.parse(json);
  let result = [];
  walkDeclarations($, (declaration) => {
    result.push(parseFontFamilyProperty(declaration.value)[0]);
  }, {
    properties: 'font-family',
    rules: (rule) => rule.type === 'font-face'
  });
  return result;
} catch (e) {
  return [];
}
''';

WITH
families AS (
  SELECT
    client,
    family,
    COUNT(DISTINCT page) AS count
  FROM
    `httparchive.all.parsed_css`,
    UNNEST(FAMILIES(css)) AS family
  WHERE
    date = '2024-07-01'
  GROUP BY
    client,
    family
),
pages AS (
  SELECT
    client,
    COUNT(DISTINCT page) AS total
  FROM
    `httparchive.all.requests`
  WHERE
    date = '2024-07-01'
  GROUP BY
    client
)

SELECT
  client,
  family,
  count,
  total,
  count / total AS proportion
FROM
  families
JOIN
  pages USING (client)
ORDER BY
  client,
  proportion DESC