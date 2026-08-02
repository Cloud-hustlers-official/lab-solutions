# 🚀 Create ML Models with BigQuery ML: Challenge Lab (GSP341)

This folder contains a **100% Zero-Touch Automation Script** to instantly complete the BigQuery ML Challenge Lab (GSP341).

## 🎯 What this script does
1. **Task 1**: Creates the `ecommerce` dataset and the `customer_classification_model` (Logistic Regression).
2. **Task 2**: Evaluates the model using `ML.EVALUATE` on unseen data (May 1 - June 30).
3. **Task 3**: Creates and evaluates the `improved_customer_classification_model` with added geographic and device features.
4. **Task 4**: Creates the `finalized_classification_model` and runs `ML.PREDICT` on data from July 2017.

## 🛠️ How to run

1. Open Cloud Shell in your Qwiklabs environment.
2. Clone the repository and run the setup script:

```bash
cd ~
curl -fsSL "https://raw.githubusercontent.com/Cloud-hustlers-official/lab-solutions/refs/heads/main/Create%20ML%20Models%20with%20BigQuery%20ML%3A%20Challenge%20Lab/cw-gsp341-setup.sh" -o cw-gsp341-setup.sh
chmod +x cw-gsp341-setup.sh
./cw-gsp341-setup.sh
```

## ⏱️ Note
BigQuery ML models take time to train (about 2-5 minutes per model). Since this script creates 3 models sequentially, **it will take about 10-15 minutes to fully complete.** Just run it, grab a coffee, and watch the green ticks appear in Qwiklabs! ☕✅
