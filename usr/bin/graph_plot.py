import pandas as pd
import matplotlib.pyplot as plt

# ---------------- READ CSV FILE ----------------
data_path = "/var/log/monitor_data.csv"

try:
    df = pd.read_csv(data_path)
except FileNotFoundError:
    print("ERROR: CSV file not found at /var/log/monitor_data.csv")
    exit()

if df.empty:
    print("ERROR: CSV file is empty.")
    exit()

# ---------------- CLEAN & CONVERT COLUMNS -------------

# Convert timestamp to datetime
try:
    df["timestamp"] = pd.to_datetime(df["timestamp"])
except Exception as e:
    print("ERROR converting timestamp:", e)
    exit()

# Convert numeric columns
for col in ["cpu", "mem", "disk"]:
    df[col] = pd.to_numeric(df[col], errors="coerce")

# Convert log_issue yes/no to 1/0
df["log_issue"] = df["log_issue"].map({"yes": 1, "no": 0})

# Remove rows with NaN values (optional but safer)
df = df.dropna()

# ---------------- CREATE 2x2 DASHBOARD ----------------

plt.figure(figsize=(16, 10))

# ---- CPU GRAPH ----
plt.subplot(2, 2, 1)
plt.plot(df["timestamp"], df["cpu"], linewidth=2)
plt.title("CPU Usage Over Time", fontsize=14, fontweight="bold")
plt.xlabel("Time")
plt.ylabel("CPU (%)")
plt.xticks(rotation=45)

# ---- MEMORY GRAPH ----
plt.subplot(2, 2, 2)
plt.plot(df["timestamp"], df["mem"], linewidth=2)
plt.title("Memory Usage Over Time", fontsize=14, fontweight="bold")
plt.xlabel("Time")
plt.ylabel("Memory (%)")
plt.xticks(rotation=45)

# ---- DISK GRAPH ----
plt.subplot(2, 2, 3)
plt.plot(df["timestamp"], df["disk"], linewidth=2)
plt.title("Disk Usage Over Time", fontsize=14, fontweight="bold")
plt.xlabel("Time")
plt.ylabel("Disk (%)")
plt.xticks(rotation=45)

# ---- LOG ALERT GRAPH ----
plt.subplot(2, 2, 4)
plt.step(df["timestamp"], df["log_issue"], where="post", linewidth=2)
plt.title("System Log Alerts Timeline", fontsize=14, fontweight="bold")
plt.xlabel("Time")
plt.ylabel("Alert (1 = yes, 0 = no)")
plt.xticks(rotation=45)

plt.tight_layout()
plt.show()


