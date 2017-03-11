#ifndef DTW_H
#define DTW_H

#include <vector>
#include <math.h>
#include <algorithm> 
#include <string>
#include <iostream>
#include <sstream>
#include <fstream>
#include <thread>
#include <windows.h>
#include <ppl.h>


#define MAXNUMBEROFTHREADS 8	//should be the number of CPU cores

using namespace std;

// function dist calculates distance between two double variables. string mode specifies the distance metric
INT64 dist(INT64 a, INT64 b, string mode)
{
	if (mode == "L1")
		return abs(a - b);

	else if (mode == "euclidean")
		return (a - b) * (a - b);	//if mode is Euclidean you'll have to take the square root of the result after DTW calculation

	else
	{
		cout << "There's no distance metric named " << mode << "implemented. Returning infinity.\n";
		return INT64_MAX;
	}

}

// function dtw calculates dynamic time warping between two double vectors, with distance metric mode, and warping window size w
//pseudo-code at: https://en.wikipedia.org/wiki/Dynamic_time_warping 
INT64 dtw(vector<INT64> tSeries1, vector<INT64> tSeries2, string mode, int w)
{
	const int size1 = tSeries1.size();
	const int size2 = tSeries2.size();

	//DTW vector is the serialized DTW matrix (first line and first column stays infinity)
	INT64* DTW = new INT64[(size1 + 1) * (size2 + 1)];

	w = max(w, abs(size1 - size2));

	//DTW matrix should be initialized with infinity
	for (int i = 1; i < (size1 + 1) * (size2 + 1); i++)
		DTW[i] = INT64_MAX;
	DTW[0] = 0;

	INT64 warpCost;

	for (int i = 1; i < size1 + 1; i++)
	{

		for (int j = max(1, i - w); j < min(size2, i + w) + 1; j++)
		{
			warpCost = dist(tSeries1[i - 1], tSeries2[j - 1], mode);
			DTW[(i)*(size2 + 1) + j] = warpCost + min(DTW[(i - 1)*(size2 + 1) + j], min((DTW[i * (size2 + 1) + j - 1]), DTW[(i - 1) * (size2 + 1) + j - 1]));
		}
	}

	INT64 toReturn=DTW[(size1 + 1) * (size2 + 1) - 1]; //return DTW distance: the last value in the matrix
	delete[] DTW;
	return toReturn;
}


// function callFromThread_wholebrain is called from each thread
void callFromThread_wholebrain(int begin, int end, vector<vector<INT64> > &data, int size, string mode, int w, string outPath)
{	
	//open txt for the output values
	ofstream output;

	stringstream ss;
	ss << outPath<<begin<<"_"<<end<<"output.txt";
	string str = ss.str();
	output.open(str);

		//calculate DTW values given to this thread
		INT64* connectivity = new INT64[size - 1];
		for (int i = begin; i < end; i++)
		{
			for (int j = i + 1; j < size; j++)
				connectivity[j - i - 1] = dtw(data[i], data[j], mode, w);
			//save DTW values to output txt
			for (int j = 0; j < size - i - 1; j++)
				output << connectivity[j] << "\t";
			output << "\n";

			//print progression
			if (i % 100 == 0)
				cout <<(i-begin)/100 <<" * 100 lines ready\n";
		}
		output.close();
		delete[] connectivity;
			
}

// function uniteOutput reads in the separate threads' outputs and creates one whole output txt
void uniteOutput(size_t* breakpoints, int maxNumberOfThreads, string mode, int w, string norm, string subname, string outPath)
{	
	//create unified output string
	ofstream uniOutput;
	stringstream st;
	
	st << outPath << subname << norm << mode << "_" << w << "_unifiedOutput.txt";
	string Str = st.str();
	uniOutput.open(Str);

	//read in each thread's output and writing it to the unified .txt
	ifstream input;
	for (int i = 0; i < maxNumberOfThreads; i++)
	{
		stringstream ss;
		
		ss << outPath << breakpoints[i] << "_" << breakpoints[i + 1] << "output.txt";
		string str = ss.str();
		input.open(str);

		string line;
		while(getline(input,line))
			uniOutput << line;
		input.close();
	}
	uniOutput.close();
	
}


//function calculateWithThreadsWholebrain distributes calculations between threads
void calculateWithThreadsWholebrain(string subname, size_t * breakpoints, vector<vector<INT64> > &data, int size, string mode, int w, string norm, string outPath)
{
	//array of threads to use (size is max-1 because the last thread is the main)
	thread threads[MAXNUMBEROFTHREADS - 1];

	//claculate parallel on the threads
	for (int i = 0; i < MAXNUMBEROFTHREADS - 1; ++i)
	{
		threads[i] = thread(callFromThread_wholebrain, breakpoints[i], breakpoints[i + 1], data, size, mode, w, outPath);
		
	}

	callFromThread_wholebrain( breakpoints[MAXNUMBEROFTHREADS - 1], breakpoints[MAXNUMBEROFTHREADS], data, size, mode, w, outPath);

	// join threads
	for (int i = 0; i < MAXNUMBEROFTHREADS - 1; ++i)
	{
		threads[i].join();
	}

	// call function to unite the output files of the threads
	uniteOutput(breakpoints, MAXNUMBEROFTHREADS, mode, w, norm, subname, outPath);
}

#endif