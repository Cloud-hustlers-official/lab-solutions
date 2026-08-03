# Create and Manage Cloud Spanner Instances: Challenge Lab | GSP381

Automation script for the **GSP381** challenge lab on Google Cloud Skills Boost.

Completes all 6 tasks:
1. Create Cloud Spanner instance (`banking-ops-instance`)
2. Create database (`banking-ops-db`)
3. Create 4 tables — Portfolio, Category, Product, Customer
4. Load simple datasets
5. Load 500-row Customer CSV (no Dataflow needed — fast & reliable)
6. Add `MarketingBudget` column

## How to Run

Open **Cloud Shell** and paste:

```bash
curl -LO https://raw.githubusercontent.com/Cloud-hustlers-official/lab-solutions/refs/heads/main/Create%20and%20Manage%20Cloud%20Spanner%20Instances%3A%20Challenge%20Lab/cs-gsp381-script.sh
chmod +x cs-gsp381-script.sh
./cs-gsp381-script.sh
```

The script auto-detects your lab's **region and zone** — no manual export needed.
After it finishes, click every **Check my progress** button in the lab.

## Features

- ✅ Auto region/zone detection from project metadata
- ✅ Auto-retry on Spanner `ABORTED` transaction errors
- ✅ No Dataflow — Customer table loads in seconds via Python client
- ✅ Fallback CSV download source if primary bucket fails

---

## 🎥 Cloud Hustlers

If this script saved your time, support the channel:

👉 **Like** 👍 | **Share** 🔁 | **Subscribe** 🔔

**YouTube:** [@cloudhustlers](https://www.youtube.com/@cloudhustlers)

New lab solutions every week — subscribe so you never miss one!

---

*For educational purposes. Use with your Qwiklabs student account only.*
