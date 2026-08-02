#!/bin/bash

# Source utils for banner and colors
source ../../bash/utils.sh

print_banner
print_info "Starting GSP341: Create ML Models with BigQuery ML..."
echo ""

# Ensure API is enabled
print_info "Enabling required APIs..."
gcloud services enable bigquery.googleapis.com

# Task 1: Create dataset and machine learning model
print_info "Task 1: Creating 'ecommerce' dataset and 'customer_classification_model'..."
bq mk --dataset ecommerce

bq query --use_legacy_sql=false "
CREATE OR REPLACE MODEL \`ecommerce.customer_classification_model\`
OPTIONS
(
model_type='logistic_reg',
labels = ['will_buy_on_return_visit']
)
AS
SELECT
  * EXCEPT(fullVisitorId)
FROM
  (SELECT
    fullVisitorId,
    IFNULL(totals.bounces, 0) AS bounces,
    IFNULL(totals.timeOnSite, 0) AS time_on_site
  FROM
    \`data-to-insights.ecommerce.web_analytics\`
  WHERE
    totals.newVisits = 1
    AND date BETWEEN '20160801' AND '20170430')
JOIN
  (SELECT
    fullvisitorid,
    IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM
    \`data-to-insights.ecommerce.web_analytics\`
  GROUP BY fullvisitorid)
USING (fullVisitorId);
"
success "Task 1 complete!"

# Task 2: Evaluate classification model performance
print_info "Task 2: Evaluating 'customer_classification_model' (May 1 - June 30)..."
bq query --use_legacy_sql=false "
SELECT
  roc_auc,
  accuracy
FROM
  ML.EVALUATE(MODEL \`ecommerce.customer_classification_model\`, (
SELECT
  * EXCEPT(fullVisitorId)
FROM
  (SELECT
    fullVisitorId,
    IFNULL(totals.bounces, 0) AS bounces,
    IFNULL(totals.timeOnSite, 0) AS time_on_site
  FROM
    \`data-to-insights.ecommerce.web_analytics\`
  WHERE
    totals.newVisits = 1
    AND date BETWEEN '20170501' AND '20170630')
JOIN
  (SELECT
    fullvisitorid,
    IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM
    \`data-to-insights.ecommerce.web_analytics\`
  GROUP BY fullvisitorid)
USING (fullVisitorId)));
"
success "Task 2 complete!"

# Task 3: Improve model performance and Evaluate
print_info "Task 3: Creating and evaluating 'improved_customer_classification_model'..."
bq query --use_legacy_sql=false "
CREATE OR REPLACE MODEL \`ecommerce.improved_customer_classification_model\`
OPTIONS
  (model_type='logistic_reg', labels = ['will_buy_on_return_visit']) AS
WITH all_visitor_stats AS (
SELECT
  fullvisitorid,
  IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
FROM \`data-to-insights.ecommerce.web_analytics\`
GROUP BY fullvisitorid
)
SELECT * EXCEPT(unique_session_id) FROM (
  SELECT
      CONCAT(fullvisitorid, CAST(visitId AS STRING)) AS unique_session_id,
      will_buy_on_return_visit,
      MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,
      IFNULL(totals.bounces, 0) AS bounces,
      IFNULL(totals.timeOnSite, 0) AS time_on_site,
      IFNULL(totals.pageviews, 0) AS pageviews,
      trafficSource.source,
      trafficSource.medium,
      channelGrouping,
      device.deviceCategory,
      IFNULL(geoNetwork.country, '') AS country
  FROM \`data-to-insights.ecommerce.web_analytics\`,
    UNNEST(hits) AS h
    JOIN all_visitor_stats USING(fullvisitorid)
  WHERE 1=1
    AND totals.newVisits = 1
    AND date BETWEEN '20160801' AND '20170430'
  GROUP BY
  unique_session_id,
  will_buy_on_return_visit,
  bounces,
  time_on_site,
  totals.pageviews,
  trafficSource.source,
  trafficSource.medium,
  channelGrouping,
  device.deviceCategory,
  country
);
"

bq query --use_legacy_sql=false "
SELECT roc_auc, accuracy FROM ML.EVALUATE(MODEL \`ecommerce.improved_customer_classification_model\`, (
  WITH all_visitor_stats AS (
  SELECT
    fullvisitorid,
    IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM \`data-to-insights.ecommerce.web_analytics\`
  GROUP BY fullvisitorid
  )
  SELECT * EXCEPT(unique_session_id) FROM (
    SELECT
        CONCAT(fullvisitorid, CAST(visitId AS STRING)) AS unique_session_id,
        will_buy_on_return_visit,
        MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,
        IFNULL(totals.bounces, 0) AS bounces,
        IFNULL(totals.timeOnSite, 0) AS time_on_site,
        IFNULL(totals.pageviews, 0) AS pageviews,
        trafficSource.source,
        trafficSource.medium,
        channelGrouping,
        device.deviceCategory,
        IFNULL(geoNetwork.country, '') AS country
    FROM \`data-to-insights.ecommerce.web_analytics\`,
      UNNEST(hits) AS h
      JOIN all_visitor_stats USING(fullvisitorid)
    WHERE 1=1
      AND totals.newVisits = 1
      AND date BETWEEN '20170501' AND '20170630'
    GROUP BY
    unique_session_id,
    will_buy_on_return_visit,
    bounces,
    time_on_site,
    totals.pageviews,
    trafficSource.source,
    trafficSource.medium,
    channelGrouping,
    device.deviceCategory,
    country
  )
));
"
success "Task 3 complete!"

# Task 4: Predict which new visitors will come back and purchase
print_info "Task 4: Creating 'finalized_classification_model' and predicting for July 2017..."
bq query --use_legacy_sql=false "
CREATE OR REPLACE MODEL \`ecommerce.finalized_classification_model\`
OPTIONS
  (model_type='logistic_reg', labels = ['will_buy_on_return_visit']) AS
WITH all_visitor_stats AS (
SELECT
  fullvisitorid,
  IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
FROM \`data-to-insights.ecommerce.web_analytics\`
GROUP BY fullvisitorid
)
SELECT * EXCEPT(unique_session_id) FROM (
  SELECT
      CONCAT(fullvisitorid, CAST(visitId AS STRING)) AS unique_session_id,
      will_buy_on_return_visit,
      MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,
      IFNULL(totals.bounces, 0) AS bounces,
      IFNULL(totals.timeOnSite, 0) AS time_on_site,
      IFNULL(totals.pageviews, 0) AS pageviews,
      trafficSource.source,
      trafficSource.medium,
      channelGrouping,
      device.deviceCategory,
      IFNULL(geoNetwork.country, '') AS country
  FROM \`data-to-insights.ecommerce.web_analytics\`,
    UNNEST(hits) AS h
    JOIN all_visitor_stats USING(fullvisitorid)
  WHERE 1=1
    AND totals.newVisits = 1
    AND date BETWEEN '20160801' AND '20170430'
  GROUP BY
  unique_session_id,
  will_buy_on_return_visit,
  bounces,
  time_on_site,
  totals.pageviews,
  trafficSource.source,
  trafficSource.medium,
  channelGrouping,
  device.deviceCategory,
  country
);
"

bq query --use_legacy_sql=false "
SELECT
  *
FROM
  ml.PREDICT(MODEL \`ecommerce.finalized_classification_model\`,
   (
   WITH all_visitor_stats AS (
SELECT
  fullvisitorid,
  IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM \`data-to-insights.ecommerce.web_analytics\`
  GROUP BY fullvisitorid
)

  SELECT * EXCEPT(unique_session_id) FROM (

    SELECT
        CONCAT(fullvisitorid, CAST(visitId AS STRING)) AS unique_session_id,

        # labels
        will_buy_on_return_visit,

        MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,

        # behavior on the site
        IFNULL(totals.bounces, 0) AS bounces,
        IFNULL(totals.timeOnSite, 0) AS time_on_site,
        IFNULL(totals.pageviews, 0) AS pageviews,

        # where the visitor came from
        trafficSource.source,
        trafficSource.medium,
        channelGrouping,

        # mobile or desktop
        device.deviceCategory,

        # geographic
        IFNULL(geoNetwork.country, \"\") AS country

    FROM \`data-to-insights.ecommerce.web_analytics\`,
      UNNEST(hits) AS h

      JOIN all_visitor_stats USING(fullvisitorid)

    WHERE 1=1
      # only predict for new visits
      AND totals.newVisits = 1
      AND date BETWEEN \"20170701\" AND \"20170801\" # predict 1 month

    GROUP BY
    unique_session_id,
    will_buy_on_return_visit,
    bounces,
    time_on_site,
    totals.pageviews,
    trafficSource.source,
    trafficSource.medium,
    channelGrouping,
    device.deviceCategory,
    country
  )
  )
)
ORDER BY
  predicted_will_buy_on_return_visit DESC;
"
success "Task 4 complete!"

echo ""
echo -e "${GREEN}${BOLD}🎉 ALL TASKS COMPLETE! Go back to Qwiklabs and check your progress!${NC}"
