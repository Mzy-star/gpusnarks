#include <cuda.h>
#include <cuda_runtime.h>
#include <stdio.h>
#include <math.h>
#include <assert.h>
#include <vector>
#include <iostream>


#define NUM_THREADS 1024
#define LOG_NUM_THREADS 10

#define CUDA_CALL( call )               \
{                                       \
cudaError_t result = call;              \
if ( cudaSuccess != result )            \
    std::cerr << "CUDA error " << result << " in " << __FILE__ << ":" << __LINE__ << ": " << cudaGetErrorString( result ) << " (" << #call << ")" << std::endl;  \
}

__device__ __forceinline__
size_t bitreverse(size_t n, const size_t l)
{
    size_t r = 0;
    for (size_t k = 0; k < l; ++k)
    {
        r = (r << 1) | (n & 1);
        n >>= 1;
    }
    return r;
}

template<typename FieldT>  __global__ void cuda_fft(
		FieldT *field, size_t length, FieldT * omega, FieldT * one)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;

    if(idx == 0)
    {
        //TODO maybe pad array with zeroes

    }
    size_t block_length = length / NUM_THREADS;
    size_t startidx = idx * block_length;
    size_t log_m = log2f(length);
    assert (length == 1ul<<log_m);
    if(startidx + block_length > length)
        return;

    FieldT *a = (FieldT*)malloc(block_length * sizeof(FieldT));
    memcpy(a, field, block_length * sizeof(FieldT));

    FieldT omega_j = *omega^idx;
    FieldT omega_step = *omega^(idx<<(log_m - LOG_NUM_THREADS));

    FieldT elt = *one;
    for (size_t i = 0; i < 1ul<<(log_m - LOG_NUM_THREADS); ++i)
    {
        for (size_t s = 0; s < NUM_THREADS; ++s)
        {
            // invariant: elt is omega^(j*idx)
            size_t mod = (1u << log_m); //mod guaranteed to be 2^n
            size_t id = (i + (s<<(log_m - LOG_NUM_THREADS))) & (mod - 1);
            a[i] += field[id] * elt;
            elt *= omega_step;
        }
        elt *= omega_j;
    }

    FieldT omega_num_cpus = *omega^NUM_THREADS;

    size_t n = block_length, logn = log2f(n);
    assert (n == (1u << logn));

    /* swapping in place (from Storer's book) */
    for (size_t k = 0; k < n; ++k)
    {
        const size_t rk = bitreverse(k, logn);
        if (k < rk)
        {
            FieldT tmp = a[k];
            a[k] = a[rk];
            a[rk] = tmp;
        }
    }

    size_t m = 1; // invariant: m = 2^{s-1}
    for (size_t s = 1; s <= logn; ++s)
    {
        // w_m is 2^s-th root of unity now
        const FieldT w_m = omega_num_cpus^(n/(2*m));

        for (size_t k = 0; k < n; k += 2*m)
        {
            FieldT w = *one;
            for (size_t j = 0; j < m; ++j)
            {
                const FieldT t = w * a[k+j+m];
                a[k+j+m] = a[k+j] - t;
                a[k+j] += t;
                w *= w_m;
            }
        }
        m *= 2;
    }

    for (size_t j = 0; j < 1ul<<(log_m - LOG_NUM_THREADS); ++j)
    {
        // now: i = idx >> (log_m - log_cpus) and j = idx % (1u << (log_m - log_cpus)), for idx = ((i<<(log_m-log_cpus))+j) % (1u << log_m)
        field[(j<<LOG_NUM_THREADS) + idx] = a[j];
    }
    free(a);
}

//template __global__ void cuda_fft<int>
  //  (int *field, size_t length, const int *omega, const int *one);


template<typename FieldT> void best_fft
    (std::vector<FieldT> &a, const FieldT &omega, const FieldT &oneElem)
    {
        FieldT * array;
        CUDA_CALL( cudaMalloc((void**) &array, sizeof(FieldT) * a.size());)
 	CUDA_CALL( cudaMemcpy(array, &a[0], sizeof(FieldT) * a.size(), cudaMemcpyHostToDevice);)
        FieldT * omg;
	CUDA_CALL( cudaMalloc((void**) &omg, sizeof(FieldT));)
 	CUDA_CALL( cudaMemcpy(omg, &omega, sizeof(FieldT), cudaMemcpyHostToDevice);)

        FieldT * one;
	CUDA_CALL( cudaMalloc((void**) &one, sizeof(FieldT));)
 	CUDA_CALL( cudaMemcpy(one, &oneElem, sizeof(FieldT), cudaMemcpyHostToDevice);)

        cuda_fft<FieldT><<<8,8>>>(array, a.size(), omg, one);
        CUDA_CALL( cudaDeviceSynchronize();)
	
	FieldT * result = (FieldT*) malloc (sizeof(FieldT) * a.size());	
	cudaMemcpy(result, array, sizeof(FieldT) * a.size(), cudaMemcpyDeviceToHost);
  	a.assign(result, result + a.size());
	printf("%d tick", result[3]);
    }


int main(void) {

    size_t size = 4096;
    int * array = (int*) malloc(size * sizeof(int));
    memset(array, 0x1234, size * sizeof(int));
    std::vector<int> v(array, array+size);

    {
        best_fft<int>(v, 5678, 1);
    }
    

    for(int j = 0; j < size; j++) {
        printf("%d ", v[j]);
    }
    return 0;
}
