import matplotlib.pyplot as plt
import numpy as np

# CHANGE THE INPUT FILE
input_file = "hdsearch_client"
output_file = "output.txt"

# Read input file and extract relevant data
with open(input_file, 'r') as file:
    lines = file.readlines()

# Extract last column from lines containing "Curr time"
timestamps = [float(line.split()[-1]) for line in lines if "Curr time" in line]

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

# Define the rate parameter λ
lambda_microseconds = 100 / 1000000

# Define a range of x values for the exponential distribution
x_values = np.linspace(0, max(sorted_differences), 1000)

# Calculate the corresponding y values using the exponential PDF formula
exponential_pdf = lambda_microseconds * np.exp(-lambda_microseconds * x_values)

# Plot the sorted intervals and the exponential distribution
plt.plot(sorted_differences, marker='o', linestyle='-', label='Intervals')
plt.plot(x_values, exponential_pdf, linestyle='-', color='orange', label='Exponential Distribution (λ=100 μs)')

plt.title('Comparison of Intervals and Exponential Distribution')
plt.xlabel('Index')
plt.ylabel('Value')
plt.grid(True)
plt.legend()

# Save the sorted intervals and exponential distribution plot as sorted_graphs.png
plt.savefig('sorted_graphs.png')

# Clear the plot
plt.clf()

# Plot the probability density function (PDF) of the intervals and exponential distribution
plt.hist(sorted_differences, bins=30, density=True, alpha=0.5, color='blue', label='Intervals PDF', rwidth=0.8)
plt.plot(x_values, exponential_pdf, linestyle='-', color='orange', label='Exponential Distribution PDF')

plt.title('Probability Density Function (PDF)')
plt.xlabel('Value')
plt.ylabel('Density')
plt.grid(True)
plt.legend()

# Adjust layout to prevent axis title from being cut off
plt.tight_layout()

# Save the PDF plot as pdf_output.png
plt.savefig('pdf_output.png')

# Display the PDF plot
plt.show()
