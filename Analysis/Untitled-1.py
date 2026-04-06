import pandas as pd
from scipy.stats import mannwhitneyu
import matplotlib.pyplot as plt

# -------------------------
# 1. Load your Excel data
# -------------------------
file_path = r"D:\eco_impact_app\Analysis\Survey.xlsx"
df = pd.read_excel(file_path, sheet_name="Form Responses 1")

# -------------------------
# 2. Define survey items
# -------------------------
cols = {
    "Awareness": "The tool/app made me more aware of the environmental impact of my social media usage.",
    "Reflection": "The tool/app made me reflect on my digital carbon footprint.",
    "Motivation": "The tool/app motivated me to reduce unnecessary social media usage to lower my carbon emissions.",
    "Belief": "I believe tools/apps like this can contribute to sustainable digital practices."
}

# -------------------------
# 3. Run Mann–Whitney U test
# -------------------------
results = []

for label, col in cols.items():
    control = df[df["Group"]=="Control"][col].dropna()
    exp = df[df["Group"]=="Experimental"][col].dropna()
    u_stat, p_val = mannwhitneyu(control, exp, alternative="two-sided")
    results.append([label, control.median(), exp.median(), u_stat, p_val])

results_df = pd.DataFrame(results, columns=["Survey Item","Median (Control)","Median (Experimental)","U-value","p-value"])
print("=== Mann–Whitney U Test Results ===")
print(results_df)

# -------------------------
# 4. Create Boxplot (Awareness)
# -------------------------
plt.figure(figsize=(6,5))
df.boxplot(column=cols["Awareness"], by="Group", grid=False)
plt.title("Awareness Scores by Group")
plt.suptitle("")
plt.ylabel("Likert Scale (1–5)")
plt.show()

# -------------------------
# 5. Create Bar Chart (Group averages for all 4 items)
# -------------------------
group_means = {}
for label, col in cols.items():
    group_means[label] = df.groupby("Group")[col].mean()

group_means = pd.DataFrame(group_means).T

group_means.plot(kind="bar", figsize=(8,6))
plt.title("Average Scores by Group")
plt.ylabel("Mean Likert Score (1–5)")
plt.xticks(rotation=0)
plt.legend(title="Group")
plt.show()
