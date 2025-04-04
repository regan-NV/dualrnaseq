#!/usr/bin/env python3
import pandas as pd
import argparse
import os


def read_count_file(file_path, sample_name):
    # HTSeq-count files typically have two columns: gene_id and count
    # with no header, so we need to handle that differently
    df = pd.read_csv(
        file_path, sep='\t', header=None, names=['gene_id', sample_name]
        )
    return df


def main():
    parser = argparse.ArgumentParser(
        description="Merge multiple HTSeq-count files into a single table.")
    parser.add_argument(
        "-i", "--inputs", nargs="+",
        required=True, help="List of input count files")
    parser.add_argument(
        "-o", "--output", required=True, help="Output merged file name")
    args = parser.parse_args()

    input_files = args.inputs
    output_file = args.output

    merged_df = None

    for file in input_files:
        sample_name = os.path.splitext(os.path.basename(file))[0]
        df = read_count_file(file, sample_name)

        if merged_df is None:
            merged_df = df
        else:
            # Merge on gene_id instead of transcript_id
            merged_df = pd.merge(merged_df, df, on="gene_id", how="outer")

    # Fill NaN values with 0 for count data
    merged_df = merged_df.fillna(0)
    merged_df.to_csv(output_file, sep="\t", index=False)
    print(f"Merged file written to {output_file}")


if __name__ == "__main__":
    main()
