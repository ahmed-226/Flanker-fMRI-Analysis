import os
import glob
from scipy.stats import ttest_1samp

# List to store results
results = []

# Loop over all copeX_clusterY_data.txt files in the current directory
for data_file in glob.glob("cope*_cluster*_data.txt"):
    # Extract cope and cluster numbers from the file name
    # Example: cope1_cluster1_data.txt -> cope=1, cluster=1
    parts = data_file.split("_")
    cope = int(parts[0].replace("cope", ""))
    cluster = int(parts[1].replace("cluster", ""))

    # Read the z-stat values from the file
    z_stats = []
    try:
        with open(data_file, "r") as df:
            for line in df:
                value = float(line.strip())
                z_stats.append(value)
        if not z_stats:
            raise ValueError("No valid data found in file")
    except (ValueError, IOError) as e:
        print(f"Error reading {data_file}: {e}")
        continue

    # Perform one-sample t-test against null hypothesis (mean z-stat = 0)
    t_stat, p_value = ttest_1samp(z_stats, popmean=0)
    mean_z_stat = sum(z_stats) / len(z_stats)

    # Store the result
    results.append((cope, cluster, mean_z_stat, t_stat, p_value))

# Sort results by COPE and then by Cluster
results.sort(key=lambda x: (x[0], x[1]))

# Write sorted results to results.txt
with open("results.txt", "w") as f:
    f.write("COPE\tCluster\tMean Z-Stat\tT-Statistic\tP-Value\n")
    for cope, cluster, mean_z_stat, t_stat, p_value in results:
        f.write(f"COPE {cope}\tCluster {cluster}\t{mean_z_stat:.4f}\t{t_stat:.4f}\t{p_value:.4f}\n")

print("Sorted results written to results.txt")
