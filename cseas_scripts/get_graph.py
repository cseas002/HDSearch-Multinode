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

# Plot the sorted differences
plt.plot(sorted_differences, marker='o', linestyle='-', label='Sorted Differences')

# Generate random numbers from an exponential distribution with lambda = 100 microseconds
num_points = len(sorted_differences)
lambda_microseconds = 100 / 1000000
exponential_data = np.random.exponential(scale=1/lambda_microseconds, size=num_points)

# Sort the randomly generated points
sorted_exponential_data = np.sort(exponential_data)

# Plot the sorted exponential distribution
plt.plot(sorted_exponential_data, marker='s', linestyle='-', color='orange', label='Sorted Exponential Distribution (λ=100 μs)')

plt.title('Comparison of Sorted Differences and Sorted Exponential Distribution')
plt.xlabel('Index')
plt.ylabel('Value')
plt.grid(True)
plt.legend()

# Save the plot as output.png
plt.savefig('output.png')

# Display the plot
plt.show()

# Display the plot
plt.show()