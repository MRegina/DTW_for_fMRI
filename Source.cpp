#include "dtw.h"
#include "readin.h"
#include <thread>
#include <windows.h>
#include <ppl.h>


int main()
{
	cout << "path of input txt with subject names, path for input time-series data, and dataset and run IDs \n";
	string inputNames;
	cin >> inputNames;

	cout << "enter number of datasets: \n";	//e.g. measurement occasions per subject
	int noDatasets;
	cin >> noDatasets;

	cout << "enter number of runs per dataset: \n"; //runs per measurement occasions
	int noRuns;
	cin >> noRuns;

	cout << "enter TR in seconds: \n";
	double TR;
	cin >> TR;

	cout << "path of output main directory\n";	//the directory where you create folders outputPath/Output'datasetID''runID' e.g. Output11 for first occasion's first measurement for every subject
	string outputPath;
	cin >> outputPath;


	//read in the subjectnames and time-series from the inputNames .txt
	ifstream inputNStream;
	inputNStream.open(inputNames);

	string line;
	string subname;
	string input;
	int dataset;
	int run;

	//read in line-by-line
	while (getline(inputNStream, line))

	{
		readInNames(line, subname, input, dataset, run);
		//print subject name
		cout << subname << "\n";;

		//output path
		stringstream os;
		os << outputPath << "output" << dataset << run << "\\";
		string outPath = os.str();

		//print where do we read in from, and where will we write out the results
		cout << input << "\n" << outPath << "\n";

		//structure for holding our timeseries data
		vector<vector<INT64> > data;

		readIn(input, data);

				//print when we finished reading in the time-series data 
				cout << "readin ready\n";

				const size_t size = data.size();	//number of time-series (columns of the input file)


				//breakpoints are the indices between each thread calculates dtw
				size_t breakpoints[MAXNUMBEROFTHREADS + 1];
				breakpoints[0] = 0;

				
				//for wholebrain connectivity calculation: we have size*(size-1)/2 DTW distance to calculate, we have to divide it evenly between threads
				int sum = 0, j = 1;
				for (size_t i = 0; i < size - 1; i++)
				{
					sum += size - 1 - i;
					if (sum >(size * (size - 1) / 2 / MAXNUMBEROFTHREADS))
					{
						breakpoints[j] = i;
						j++;
						sum = 0;
					}
				}
				breakpoints[MAXNUMBEROFTHREADS] = size;


				// to normalize timeserieses to zero mean and 1 standard deviation
				static const int tSize = data[0].size();
				double* means = new double[size];
				double* vars = new double[size];

				for (int i = 0; i < size; i++)
				{
					means[i] = 0;
					vars[i] = 0;
					for (int j = 0; j < tSize; j++)
					{
						means[i] += data[i][j];
						vars[i] += (data[i][j])*(data[i][j]);
					}
					means[i] = means[i] / tSize;
					vars[i] = sqrt(vars[i] / tSize - means[i] * means[i]); 
					
					//we don't want to divide with zero
					if (vars[i] < 0.1)
					{
						vars[i] = 0.1;
					}

					//normalize data
					for (int j = 0; j < tSize; j++)
					{
						data[i][j] = (INT64)((((double)data[i][j] - means[i]) / vars[i]) * 10000);
					}
				}

				delete[] means;
				delete[] vars;


				// calculate warping window size: for resting state it should be around 100 s
				int warpingWindow = round(100 / TR);
				
				// call function to run calculations in parallel
				calculateWithThreadsWholebrain(subname, breakpoints, data, size, "euclidean", warpingWindow, "normalized_", outPath);
			
		
		
	}

	

	//keep the window open
	int x;
	cin >> x;
}