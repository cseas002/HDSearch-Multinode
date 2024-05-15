import matplotlib.pyplot as plt
import numpy as np
from scipy.stats import poisson

# CHANGE THE INPUT FILE
input_file = "hdsearch_client"
output_file = "output.txt"

# Read input file and extract relevant data
with open(input_file, 'r') as file:
    lines = file.readlines()

# Extract last column from lines containing "Curr time"
timestamps = [float(line.split()[-1]) for line in lines if "Poisson time" in line]

# Calculate differences between consecutive values
differences = [timestamps[i+1] - timestamps[i] for i in range(len(timestamps)-1)]

# Write results to output file
with open(output_file, 'w') as file:
    # file.write("Differences:\n")
    for diff in differences:
        file.write(f"{diff}\n")

# Read differences from the output file
with open("output.txt", "r") as file:
    differences = [float(line.strip()) for line in file if line.strip()]

# Sort the differences
sorted_differences = sorted(differences)

# print(sorted_differences)

# Calculate the rate parameter λ
lambda_microseconds = 10000  # Lambda = 100000 μs

# Create a Poisson distribution object with lambda parameter
poisson_dist = poisson(mu=lambda_microseconds)

# Define a range of x values for the Poisson distribution
x_values = np.arange(0, max(sorted_differences), 1)

# Calculate the corresponding PMF values using the Poisson PMF formula
poisson_pmf = poisson_dist.pmf(x_values)

# Plot the sorted intervals and the Poisson distribution PMF
plt.plot(sorted_differences, marker='o', linestyle='-', label='Intervals')
plt.plot(x_values, poisson_pmf, linestyle='-', color='orange', label='Poisson Distribution (λ=100 ms)')

plt.title('Comparison of Intervals and Poisson Distribution')
plt.xlabel('Index')
plt.ylabel('Value')
plt.grid(True)
plt.legend()

# Save the sorted intervals and Poisson distribution plot as sorted_poisson_graphs.png
plt.savefig('sorted_poisson_graphs.png')

# Clear the plot
plt.clf()

# Plot the probability density function (PDF) of the intervals and Poisson distribution
plt.hist(sorted_differences, bins=100, density=True, alpha=0.5, color='blue', label='Intervals PDF', rwidth=0.8)
plt.plot(x_values, poisson_pmf, linestyle='-', color='orange', label='Poisson Distribution PMF')

plt.title('Probability Density Function (PDF)')
plt.xlabel('Request Interval (μs)')
plt.ylabel('Density')
plt.grid(True)
plt.legend()

# Adjust layout to prevent axis title from being cut off
plt.tight_layout()

# Save the PDF plot as poisson_pdf_output.png
plt.savefig('poisson_pdf_output.png')

# Display the PDF plot
plt.show()
