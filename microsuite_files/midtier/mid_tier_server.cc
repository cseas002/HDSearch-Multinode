/* Author: Akshitha Sriraman
   Ph.D. Candidate at the University of Michigan - Ann Arbor*/

#include <memory>
#include <omp.h>
#include <iostream>
#include <string>
#include <thread>

#include <condition_variable>
#include <mutex>
// #include <pthread.h>

#include <grpc++/grpc++.h>

#include "bucket_service/service/helper_files/client_helper.h"
#include "mid_tier_service/service/helper_files/mid_tier_server_helper.h"
#include "mid_tier_service/service/helper_files/timing.h"
#include "mid_tier_service/service/helper_files/utils.h"

// Helper thread code
#include <atomic>
#include <chrono>

// Pre-request code

#include <vector>
#include <arpa/inet.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <sys/socket.h>
#include <unistd.h>
#include <signal.h>
#include <math.h>
#include <stdbool.h>
// #include <gsl/gsl_randist.h>
#define PORT 8080
#define PORT2 8081

// Global variables
int send_request_usecs_wait = 0;
bool pre_request = true;
int client_fd1;

int previous_average_time = 0;
int process_request_count = 0;
bool increasing = false;
int step = 100;
bool adaptive = true;
std::vector<long> times_taken;

// Signal handler for SIGPIPE
void sigpipe_handler(int signo)
{
    // Do nothing, just ignore the signal
}

int send_request(bool read_message, int client_fd, char *hello, char *buffer, int port)
{
    struct timeval start_time, end_time;
    // Measure the time before sending the pre request
    gettimeofday(&start_time, NULL);

    // Send to port 8080
    int r = send(client_fd, hello, strlen(hello), 0);
    // printf("Pre request sent to port 8080\n");
    if (r <= 0)
    {
        perror("Error sending to port");
        return -1;
    }

    // Receive from port
    if (read_message)
    {
        int valread = read(client_fd, buffer, 30);
        if (valread <= 0)
        {
            perror("Error reading from port");
            return -1;
        }
        printf("Read reply: \n");
    }

    // Measure the time after sending to port
    gettimeofday(&end_time, NULL);
    long elapsed_time = end_time.tv_usec - start_time.tv_usec;

    // printf("Time taken for send to port %d: %ld microseconds\n", port, elapsed_time);

    // printf("Message from port 8080: %s\n", buffer);
    return elapsed_time;
}

int compare_long(const void *a, const void *b)
{
    return (*(long *)a - *(long *)b);
}

void print_statistics(int repetitions, long *latency_array)
{
    // Calculate and print average latency
    long long sum_latency = 0;
    for (int i = 0; i < repetitions; i++)
    {
        sum_latency += latency_array[i];
    }
    long double average_latency = (long double)sum_latency / repetitions;
    printf("Average Latency: %.2Lf microseconds\n", average_latency);

    // Sort the latency array to find the 99th percentile
    qsort(latency_array, repetitions, sizeof(long), compare_long);

    // Calculate and print the 99th percentile latency
    int index_99th = (int)(0.99 * repetitions);
    long percentile_99th = latency_array[index_99th];
    printf("99th Percentile Latency: %ld microseconds\n", percentile_99th);
}

// End of pre-request code

// Helper thread code

// void print_affinity(const std::string& thread_name) {
//     cpu_set_t cpuset;
//     CPU_ZERO(&cpuset);
//     pthread_getaffinity_np(pthread_self(), sizeof(cpu_set_t), &cpuset);

//     std::cout << thread_name << " running on CPU(s): ";
//     for (int j = 0; j < CPU_SETSIZE; ++j) {
//         if (CPU_ISSET(j, &cpuset)) {
//             std::cout << j << " ";
//         }
//     }
//     std::cout << std::endl;
// }

// Define a global atomic flag
std::atomic<bool> sendRequestFlag(false);
std::mutex mtx;
std::condition_variable cv;

// Function that waits for the flag to be set
void waitForFlag()
{
    std::unique_lock<std::mutex> lock(mtx);
    cv.wait(lock, []
            { return sendRequestFlag.load(std::memory_order_acquire); });
    // Flag is now true, proceed with the rest of the function
}

// Function that sets the flag and notifies the waiting thread
void setFlag()
{
    {
        std::lock_guard<std::mutex> lock(mtx);
        sendRequestFlag.store(true, std::memory_order_release);
    }
    cv.notify_one();
}

// Function to be executed by the helper thread
void helperThreadFunction(int client_fd1, char *hello, char *buffer, int port)
{
    if (send_request_usecs_wait >= 0) // If it's negative, it will not send a pre-request
    {
        printf("Pre request sending enabled\n");
        // Make this without busy waiting
        while (true)
        {
            // Wait until the flag is set to true
            while (!sendRequestFlag.load(std::memory_order_acquire))
            {
            }
            if (send_request_usecs_wait > 0)
            {
                struct timeval start_time, end_time;
                gettimeofday(&end_time, NULL); // Assign the end_time a low value initially
                gettimeofday(&start_time, NULL);

                // Instead of sleep(send_request_usecs_wait), I actively read the current timestamp and check whether the <send_request_usecs_wait> us have passed
                // Also, I need to check that while waiting, I still want to send the pre-request

                // sleep(send_request_usecs_wait);
                while (end_time.tv_usec - start_time.tv_usec < send_request_usecs_wait && sendRequestFlag.load(std::memory_order_acquire))
                {
                    gettimeofday(&end_time, NULL);
                }
            }

            if (sendRequestFlag.load(std::memory_order_acquire))
            {
                // Once the send_request_usecs_wait us have passed, send the request
                printf("Pre-request sent\n");
                send_request(true, client_fd1, hello, buffer, port); // Changed this to true so I can see the message
            }

            // Reset the flag
            sendRequestFlag.store(false, std::memory_order_release);
        }
    }
}

// Function to be executed by the helper thread
void helperThreadFunctionNoBusyWait(int client_fd1, char *hello, char *buffer, int port)
{
    if (send_request_usecs_wait >= 0) // If it's negative, it will not send a pre-request
    {
        printf("Pre request sending enabled\n");

        usleep(send_request_usecs_wait);
        // while (end_time.tv_usec - start_time.tv_usec < send_request_usecs_wait && sendRequestFlag.load(std::memory_order_acquire))
        // {
        //     gettimeofday(&end_time, NULL);
        // }

        if (sendRequestFlag.load(std::memory_order_acquire))
        {
            // Once the send_request_usecs_wait us have passed, send the request
            printf("Pre-request sent\n");
            send_request(true, client_fd1, hello, buffer, port); // Changed this to true so I can see the message
        }

        // Reset the flag
        sendRequestFlag.store(false, std::memory_order_release);
    }
}
// End of helper thread code

#define FIXEDCOMP 10

using namespace flann;

using grpc::Server;
using grpc::ServerAsyncResponseWriter;
using grpc::ServerBuilder;
using grpc::ServerCompletionQueue;
using grpc::ServerContext;
using grpc::Status;
using loadgen_index::LoadGenIndex;
using loadgen_index::LoadGenRequest;
using loadgen_index::PointIds;
using loadgen_index::ResponseIndexKnnQueries;

using bucket::DataPoint;
using bucket::DistanceService;
using bucket::MultipleDataPoints;
using bucket::NearestNeighborRequest;
using bucket::NearestNeighborResponse;
using bucket::PointIdList;
using bucket::TimingDataInMicro;
using grpc::Channel;
using grpc::ClientAsyncResponseReader;
using grpc::ClientContext;
using grpc::CompletionQueue;
using grpc::Status;

// Class declarations.
class ServerImpl;
class DistanceServiceClient;

// Function declarations.
void ProcessRequest(LoadGenRequest &load_gen_request,
                    uint64_t unique_request_id_value,
                    int tid);

// Global variable declarations.
/* dataset_dim is global so that we can validate query dimensions whenever
   batches of queries are received.*/
unsigned int dataset_dimensions = 0, num_hash_tables = 0, hash_table_key_length = 0, num_multi_probe_levels = 0, number_of_bucket_servers = 0;
long dataset_size = 0;
int mode = 0, network_poller_parallelism = 0, dispatch_parallelism = 0, number_of_response_threads = 0;
std::string ip = "localhost";
std::vector<std::string> bucket_server_ips;
/* lsh_index is global so that the server can build/load the index in the very
   beginning, before it accepts any queries. Subsequent queries can then use
   this index structure already built, to get point IDs.*/
Index<L2<unsigned char>> lsh_index;
std::vector<std::map<unsigned int, std::vector<std::vector<unsigned int>>>> *tables_of_vectors = new std::vector<std::map<unsigned int, std::vector<std::vector<unsigned int>>>>();
MultiplePoints dataset_multiple_points;
uint64_t num_requests = 0;
std::vector<DistanceServiceClient *> bucket_connections;
/* Server object is global so that the async bucket client
   thread can access it after it has merged all responses.*/
ServerImpl *server;
ResponseMap response_count_down_map;

ThreadSafeQueue<bool> kill_notify;
/* Fine grained locking while looking at individual responses from
   multiple bucket servers. Coarse grained locking when we want to add
   or remove an element from the map.*/
std::mutex response_map_mutex, thread_id, bucket_server_id_mutex, map_coarse_mutex;
std::vector<mutex_wrapper> bucket_conn_mutex;
std::map<uint64_t, std::unique_ptr<std::mutex>> map_fine_mutex;
int get_profile_stats = 0;
bool first_req = false;

CompletionQueue *bucket_cq = new CompletionQueue();

bool kill_signal = false;

ThreadSafeQueue<DispatchedData *> dispatched_data_queue;
std::mutex dispatched_data_queue_mutex;
Atomics *started = new Atomics();

class ServerImpl final
{
public:
    ~ServerImpl()
    {
        server_->Shutdown();
        // Always shutdown the completion queue after the server.
        cq_->Shutdown();
    }

    // There is no shutdown handling in this code.
    void Run()
    {
        std::string ip_port = ip;
        std::string server_address(ip_port);

        ServerBuilder builder;
        // Listen on the given address without any authentication mechanism.
        builder.AddListeningPort(server_address, grpc::InsecureServerCredentials());
        // Register "service_" as the instance through which we'll communicate with
        // clients. In this case it corresponds to an *asynchronous* service.
        builder.RegisterService(&service_);
        // Get hold of the completion queue used for the asynchronous communication
        // with the gRPC runtime.
        cq_ = builder.AddCompletionQueue();
        // Finally assemble the server.
        server_ = builder.BuildAndStart();
        std::cout << "Server listening on " << server_address << std::endl;

        std::vector<std::thread> worker_threads;
        for (int i = 0; i < dispatch_parallelism; i++)
        {
            /* Launch the dispatch threads. When there are
               no requests, the threads just keeps spinning on a
               "dispatch queue".*/
            worker_threads.emplace_back(std::thread(&ServerImpl::Dispatch, this, i));
        }

        // Proceed to the server's main loop.
        /* This section of the code is parallelized to handle
           multiple requests at once.*/
        omp_set_dynamic(0);
        omp_set_nested(1);
        omp_set_num_threads(network_poller_parallelism);
        int tid = -1;
#pragma omp parallel
        {
            thread_id.lock();
            int tid_local = ++tid;
            thread_id.unlock();
            HandleRpcs(tid_local);
        }

        for (int i = 0; i < dispatch_parallelism; i++)
        {
            worker_threads[i].join();
        }
    }

    void Finish(uint64_t unique_request_id,
                ResponseIndexKnnQueries *index_reply)
    {

        CallData *call_data_req_to_finish = (CallData *)unique_request_id;
        call_data_req_to_finish->Finish(index_reply);
    }

private:
    // Class encompasing the state and logic needed to serve a request.
    class CallData
    {
    public:
        // Take in the "service" instance (in this case representing an asynchronous
        // server) and the completion queue "cq" used for asynchronous communication
        // with the gRPC runtime.
        CallData(LoadGenIndex::AsyncService *service, ServerCompletionQueue *cq)
            : service_(service), cq_(cq), responder_(&ctx_), status_(CREATE)
        {
            // Invoke the serving logic right away.
            int tid = 0;
            Proceed(tid);
        }

        void Proceed(int tid)
        {
            if (status_ == CREATE)
            {
                // Make this instance progress to the PROCESS state.
                status_ = PROCESS;

                // As part of the initial CREATE state, we *request* that the system
                // start processing SayHello requests. In this request, "this" acts are
                // the tag uniquely identifying the request (so that different CallData
                // instances can serve different requests concurrently), in this case
                // the memory address of this CallData instance.
                service_->RequestLoadGen_Index(&ctx_, &load_gen_request_, &responder_, cq_, cq_,
                                               this);
            }
            else if (status_ == PROCESS)
            {
                // Spawn a new CallData instance to serve new clients while we process
                // the one for this CallData. The instance will deallocate itself as
                // part of its FINISH state.
                new CallData(service_, cq_);
                uint64_t unique_request_id_value = reinterpret_cast<uintptr_t>(this);
                // uint64_t unique_request_id_value = num_reqs->AtomicallyIncrementCount();
                //  The actual processing.
                ProcessRequest(load_gen_request_,
                               unique_request_id_value,
                               tid);
                // And we are done! Let the gRPC runtime know we've finished, using the
                // memory address of this instance as the uniquely identifying tag for
                // the event.
                // status_ = FINISH;
                // responder_.Finish(index_reply_, Status::OK, this);
            }
            else
            {
                // GPR_ASSERT(status_ == FINISH);
                //  Once in the FINISH state, deallocate ourselves (CallData).
                delete this;
            }
        }

        void Finish(ResponseIndexKnnQueries *index_reply)
        {
            status_ = FINISH;
            // GPR_ASSERT(status_ == FINISH);
            responder_.Finish(*index_reply, Status::OK, this);
        }

    private:
        // The means of communication with the gRPC runtime for an asynchronous
        // server.
        LoadGenIndex::AsyncService *service_;
        // The producer-consumer queue where for asynchronous server notifications.
        ServerCompletionQueue *cq_;
        // Context for the rpc, allowing to tweak aspects of it such as the use
        // of compression, authentication, as well as to send metadata back to the
        // client.
        ServerContext ctx_;
        // What we get from the client.
        LoadGenRequest load_gen_request_;
        // What we send back to the client.
        ResponseIndexKnnQueries index_reply_;

        // The means to get back to the client.
        ServerAsyncResponseWriter<ResponseIndexKnnQueries> responder_;

        // Let's implement a tiny state machine with the following states.
        enum CallStatus
        {
            CREATE,
            PROCESS,
            FINISH
        };
        CallStatus status_; // The current serving state.
    };

    /* Function called by thread that is the worker. Network poller
       hands requests to this worker thread via a
       producer-consumer style queue.*/
    void Dispatch(int worker_tid)
    {
        /* Continuously spin and keep checking if there is a
           dispatched request that needs to be processed.*/
        while (true)
        {
            /* As long as there is a request to be processed,
               process it. Outer while is just to ensure
               that we keep waiting for a request when there is
               nothing in the queue.*/
            DispatchedData *dispatched_request = dispatched_data_queue.pop();
            static_cast<CallData *>(dispatched_request->tag)->Proceed(worker_tid);
            delete dispatched_request;
        }
    }

    // This can be run in multiple threads if needed.
    void HandleRpcs(int tid)
    {
        // Spawn a new CallData instance to serve new clients.
        new CallData(&service_, cq_.get());
        void *tag; // uniquely identifies a request.
        bool ok;
        int cnt = 0;
        while (true)
        {
            // Block waiting to read the next event from the completion queue. The
            // event is uniquely identified by its tag, which in this case is the
            // memory address of a CallData instance.
            cq_->Next(&tag, &ok);
            if (cnt == 0)
            {
                cnt++;
                kill_notify.push(true);
            }
            /* When we have a new request, we create a new object
               to the dispatch queue.*/
            DispatchedData *request_to_be_dispatched = new DispatchedData();
            request_to_be_dispatched->tag = tag;
            dispatched_data_queue.push(request_to_be_dispatched);
            // GPR_ASSERT(ok);
        }
    }

    std::unique_ptr<ServerCompletionQueue> cq_;
    LoadGenIndex::AsyncService service_;
    std::unique_ptr<Server> server_;
};

/* Declaring bucket client here because the index server must
   invoke the bucket client to send the queries+PointIDs to the bucket server.*/
class DistanceServiceClient
{
public:
    explicit DistanceServiceClient(std::shared_ptr<Channel> channel)
        : stub_(DistanceService::NewStub(channel)) {}
    /* Assambles the client's payload, sends it and presents the response back
       from the server.*/
    void GetNearestNeighbors(const MultiplePoints &queries,
                             const std::vector<std::vector<uint32_t>> &point_ids,
                             const unsigned int &queries_size,
                             const int &number_of_nearest_neighbors,
                             const uint32_t bucket_server_id,
                             const int &shard_size,
                             const bool util_present,
                             uint64_t request_id,
                             NearestNeighborRequest &request_to_bucket)
    {
        // Get the dimension.
        int dimension = queries.GetPointAtIndex(0).GetSize();
        // Declare the set of queries that must be sent.
        uint64_t start_time = GetTimeInMicro();
        // Create RCP request by adding queries, point IDs, and number of NN.
        CreateBucketServiceRequest(queries,
                                   point_ids,
                                   queries_size,
                                   number_of_nearest_neighbors,
                                   dimension,
                                   bucket_server_id,
                                   shard_size,
                                   util_present,
                                   &request_to_bucket);
        request_to_bucket.set_request_id(request_id);
        uint64_t end_time = GetTimeInMicro();
        // bucket_timing_info->create_bucket_request_time = end_time - start_time;
        //  Container for the data we expect from the server.
        NearestNeighborResponse reply;
        // Context for the client.
        ClientContext context;
        // Call object to store rpc data
        AsyncClientCall *call = new AsyncClientCall;
        // stub_->AsyncSayHello() performs the RPC call, returning an instance to
        // store in "call". Because we are using the asynchronous API, we need to
        // hold on to the "call" instance in order to get updates on the ongoing RPC.
        call->response_reader = stub_->AsyncGetNearestNeighbors(&call->context, request_to_bucket, bucket_cq);
        // Request that, upon completion of the RPC, "reply" be updated with the
        // server's response; "status" with the indication of whether the operation
        // was successful. Tag the request with the memory address of the call object.
        call->response_reader->Finish(&call->reply, &call->status, (void *)call);
    }

    // Loop while listening for completed responses.
    // Prints out the response from the server.
    void AsyncCompleteRpc()
    {
        void *got_tag;
        bool ok = false;
        bucket_cq->Next(&got_tag, &ok);
        // auto r = cq_.AsyncNext(&got_tag, &ok, gpr_time_0(GPR_CLOCK_REALTIME));
        // if (r == ServerCompletionQueue::TIMEOUT) return;
        // if (r == ServerCompletionQueue::GOT_EVENT) {
        //  The tag in this example is the memory location of the call object
        AsyncClientCall *call = static_cast<AsyncClientCall *>(got_tag);

        // Verify that the request was completed successfully. Note that "ok"
        // corresponds solely to the request for updates introduced by Finish().
        // GPR_ASSERT(ok);

        if (call->status.ok())
        {
            uint64_t s1 = GetTimeInMicro();
            uint64_t unique_request_id = call->reply.request_id();
            int number_of_nearest_neighbors = call->reply.neighbor_ids(0).point_id_size();
            /* When this is not the last response, we need to decrement the count
               as well as collect response meta data - knn answer, bucket util, and
               bucket timing info.
               When this is the last request, we remove this request from the map and
               merge responses from all buckets.*/
            /* Create local DistCalc, BucketTimingInfo, BucketUtil variables,
               so that this thread can unpack received bucket data into these variables
               and then grab a lock to append to the response array in the map.*/
            DistCalc knn_answer;
            BucketTimingInfo bucket_timing_info;
            BucketUtil bucket_util;
            uint64_t start_time = GetTimeInMicro();
            UnpackBucketServiceResponse(call->reply,
                                        number_of_nearest_neighbors,
                                        &knn_answer,
                                        &bucket_timing_info,
                                        &bucket_util);
            uint64_t end_time = GetTimeInMicro();
            // Make sure that the map entry corresponding to request id exists.
            map_coarse_mutex.lock();
            try
            {
                response_count_down_map.at(unique_request_id);
            }
            catch (...)
            {
                CHECK(false, "ERROR: Map entry corresponding to request id does not exist\n");
            }
            map_coarse_mutex.unlock();

            map_fine_mutex[unique_request_id]->lock();
            int bucket_resp_id = response_count_down_map[unique_request_id].responses_recvd;
            *(response_count_down_map[unique_request_id].response_data[bucket_resp_id].knn_answer) = knn_answer;
            *(response_count_down_map[unique_request_id].response_data[bucket_resp_id].bucket_timing_info) = bucket_timing_info;
            *(response_count_down_map[unique_request_id].response_data[bucket_resp_id].bucket_util) = bucket_util;
            response_count_down_map[unique_request_id].response_data[bucket_resp_id].bucket_timing_info->unpack_bucket_resp_time = end_time - start_time;
#if 0
                if (response_count_down_map[unique_request_id].responses_recvd == 2) {
                    uint64_t bucket_resp_start_time = response_count_down_map[unique_request_id].index_reply->get_bucket_responses_time();
                    response_count_down_map[unique_request_id].index_reply->set_get_bucket_responses_time(GetTimeInMicro() - bucket_resp_start_time);
                }
#endif
            if (response_count_down_map[unique_request_id].responses_recvd != (number_of_bucket_servers - 1))
            {
                response_count_down_map[unique_request_id].responses_recvd++;
                map_fine_mutex[unique_request_id]->unlock();
            }
            else
            {
                uint64_t bucket_resp_start_time = response_count_down_map[unique_request_id].index_reply->get_bucket_responses_time();
                response_count_down_map[unique_request_id].index_reply->set_get_bucket_responses_time(GetTimeInMicro() - bucket_resp_start_time);
                /* Time to merge all responses received and then
                   call terminate so that the response can be sent back
                   to the load generator.*/
                /* We now know that all buckets have responded, hence we can
                   proceed to merge responses.*/
                unsigned int queries_size = call->reply.queries_size();
                unsigned int query_dimensions = 2048;

                /* We now know that all buckets have responded, hence we can
                   proceed to merge responses.*/
                Point p(query_dimensions, 0.0);
                MultiplePoints queries_multiple_points(queries_size, p);
                for (int i = 0; i < queries_size; i++)
                {
                    queries_multiple_points.SetPoint(i, dataset_multiple_points.GetPointAtIndex(call->reply.queries(i)));
                }

                start_time = GetTimeInMicro();
                MergeAndPack(response_count_down_map[unique_request_id].response_data,
                             dataset_multiple_points,
                             queries_multiple_points,
                             queries_size,
                             query_dimensions,
                             number_of_bucket_servers,
                             number_of_nearest_neighbors,
                             response_count_down_map[unique_request_id].index_reply);
                end_time = GetTimeInMicro();
                response_count_down_map[unique_request_id].index_reply->set_merge_time(end_time - start_time);
                response_count_down_map[unique_request_id].index_reply->set_pack_index_resp_time(end_time - start_time);
                // response_count_down_map[unique_request_id].index_reply->set_index_time(index_times[unique_request_id]);
                /* Call server finish for this particular request,
                   and pass the response so that it can be sent
                   by the server to the frontend.*/
                uint64_t prev_rec = response_count_down_map[unique_request_id].index_reply->index_time();
                response_count_down_map[unique_request_id].index_reply->set_index_time(prev_rec + (GetTimeInMicro() - s1));
                map_fine_mutex[unique_request_id]->unlock();

                map_coarse_mutex.lock();
                server->Finish(unique_request_id,
                               response_count_down_map[unique_request_id].index_reply);
                map_coarse_mutex.unlock();
            }
        }
        else
        {
            CHECK(false, "Bucket no longer exists\n");
        }
        // Once we're complete, deallocate the call object.
        delete call;
    }

private:
    // struct for keeping state and data information
    struct AsyncClientCall
    {
        // Container for the data we expect from the server.
        NearestNeighborResponse reply;
        // Context for the client. It could be used to convey extra information to
        // the server and/or tweak certain RPC behaviors.
        ClientContext context;
        // Storage for the status of the RPC upon completion.
        Status status;
        std::unique_ptr<ClientAsyncResponseReader<NearestNeighborResponse>> response_reader;
    };

    // Out of the passed in Channel comes the stub, stored here, our view of the
    // server's exposed services.
    std::unique_ptr<DistanceService::Stub> stub_;

    // The producer-consumer queue we use to communicate asynchronously with the
    // gRPC runtime.
    CompletionQueue cq_;
};

// THIS IS CALLED WHEN A NEW REQUEST IS RECEIVED
void ProcessRequest(LoadGenRequest &load_gen_request,
                    uint64_t unique_request_id_value,
                    int tid)
{
    // Pre request code
    char *hello = "Hello from client";
    char buffer[30] = {0};
    // SEND PRE-REQUEST HERE

    if (send_request_usecs_wait >= 0)
    {
        // sendRequestFlag.store(true, std::memory_order_release);
        // std::thread helperThread(helperThreadFunctionNoBusyWait, client_fd1, hello, buffer, PORT);

        // Send the pre-request
        sendRequestFlag.store(true, std::memory_order_release);
        std::thread(helperThreadFunctionNoBusyWait, client_fd1, hello, buffer, PORT).detach();

        printf("Sending pre-request\n");

        // usleep(send_request_usecs_wait);
        // send_request(false, client_fd1, hello, buffer, 8080);
        // printf("Pre-request sent\n");
    }

    // End of pre request code

    uint64_t beginning_time = GetTimeInMicro();
    uint64_t s1 = 0, e1 = 0;
    s1 = GetTimeInMicro();
    if (!started->AtomicallyReadFlag())
    {
        started->AtomicallySetFlag(true);
    }
    /* Deine the map entry corresponding to this
       unique request.*/
    // Get number of nearest neighbors from the request.
    unsigned int number_of_nearest_neighbors = (int)load_gen_request.number_nearest_neighbors();
    // Declare the size of the final response that the map must hold.
    map_coarse_mutex.lock();
    ResponseMetaData meta_data;
    response_count_down_map.erase(unique_request_id_value);
    map_fine_mutex.erase(unique_request_id_value);
    map_fine_mutex[unique_request_id_value] = std::make_unique<std::mutex>();
    response_count_down_map[unique_request_id_value] = meta_data;
    map_coarse_mutex.unlock();

    map_fine_mutex[unique_request_id_value]->lock();

    if (load_gen_request.kill())
    {
        kill_signal = true;
        response_count_down_map[unique_request_id_value].index_reply->set_kill_ack(true);
        server->Finish(unique_request_id_value,
                       response_count_down_map[unique_request_id_value].index_reply);
        sleep(4);
        CHECK(false, "Exit signal received\n");
    }
    response_count_down_map[unique_request_id_value].responses_recvd = 0;
    response_count_down_map[unique_request_id_value].response_data.resize(number_of_bucket_servers, ResponseData());
    response_count_down_map[unique_request_id_value].index_reply->set_request_id(load_gen_request.request_id());
    response_count_down_map[unique_request_id_value].index_reply->set_num_inline(network_poller_parallelism);
    response_count_down_map[unique_request_id_value].index_reply->set_num_workers(dispatch_parallelism);
    response_count_down_map[unique_request_id_value].index_reply->set_num_resp(number_of_response_threads);
    // map_fine_mutex[unique_request_id_value]->unlock();

    bool util_present = load_gen_request.util_request().util_request();
    /* If the load generator is asking for util info,
       it means the time period has expired, so
       the index must read /proc/stat to provide user, system, and io times.*/
    if (util_present)
    {
        uint64_t start = GetTimeInMicro();
        uint64_t user_time = 0, system_time = 0, io_time = 0, idle_time = 0;
        GetCpuTimes(&user_time,
                    &system_time,
                    &io_time,
                    &idle_time);
        // map_fine_mutex[unique_request_id_value]->lock();
        response_count_down_map[unique_request_id_value].index_reply->mutable_util_response()->mutable_index_util()->set_user_time(user_time);
        response_count_down_map[unique_request_id_value].index_reply->mutable_util_response()->mutable_index_util()->set_system_time(system_time);
        response_count_down_map[unique_request_id_value].index_reply->mutable_util_response()->mutable_index_util()->set_io_time(io_time);
        response_count_down_map[unique_request_id_value].index_reply->mutable_util_response()->mutable_index_util()->set_idle_time(idle_time);
        response_count_down_map[unique_request_id_value].index_reply->mutable_util_response()->set_util_present(true);
        response_count_down_map[unique_request_id_value].index_reply->set_update_index_util_time(GetTimeInMicro() - start);
        // map_fine_mutex[unique_request_id_value]->unlock();
    }
    uint64_t start_time = GetTimeInMicro();
    // Get #queries and #dimensions from received queries.
    unsigned int queries_size = load_gen_request.query_id_size();
    unsigned int query_dimensions = 2048;
    uint64_t query_id = 0;
    // Define queries: total #dimensions, #rows/#queries, #columns/#dimensions
    Matrix<unsigned char> queries(new unsigned char[queries_size * query_dimensions],
                                  queries_size,
                                  query_dimensions);
    // Create a MultiplePoints structure to unpack queries into.
    Point p(query_dimensions, 0.0);
    MultiplePoints queries_multiple_points(queries_size, p);
    NearestNeighborRequest request_to_bucket;
    UnpackLoadgenServiceRequest(load_gen_request,
                                dataset_multiple_points,
                                queries_size,
                                query_dimensions,
                                &queries,
                                &queries_multiple_points,
                                &query_id,
                                &request_to_bucket);
    // Dataset dimension must be equal to queries dimension.
    ValidateDimensions(dataset_dimensions, query_dimensions);

    uint64_t end_time = GetTimeInMicro();
    // map_fine_mutex[unique_request_id_value]->lock();
    response_count_down_map[unique_request_id_value].index_reply->set_unpack_loadgen_req_time((end_time - start_time));
    // map_fine_mutex[unique_request_id_value]->unlock();
    // float points_sent_percent = PercentDataSent(point_ids, queries_size, dataset_size);
    // printf("Amount of dataset sent to bucket server in the form of point IDs = %.5f\n", points_sent_percent);
    //(*response_count_down_map)[unique_request_id_value]->index_reply->set_percent_data_sent(points_sent_percent);
    std::vector<std::vector<uint32_t>> point_ids;
    std::vector<std::vector<std::vector<uint32_t>>> point_ids_for_all_bucket_servers(number_of_bucket_servers, point_ids);

    start_time = GetTimeInMicro();

    for (unsigned int i = 0; i < number_of_bucket_servers; i++)
    {
        int bucket_server_id = i;
        lsh_index.getPointIDs(queries,
                              tables_of_vectors,
                              bucket_server_id,
                              flann::SearchParams(128),
                              &point_ids_for_all_bucket_servers[i]);
        // float points_sent_percent = PercentDataSent(point_ids_for_all_bucket_servers[i], queries_size, dataset_size);
        // printf("Amount of dataset sent to bucket server in the form of point IDs = %.5f\n", points_sent_percent);
        /* It is possible for no point IDs to be returned for a query.
           i.e the query did not hash to any bucket.
           LSH parameters must be chosen in a better fashion in such cases.*/
        /* We fix the number of computations that HDSearch performs
           to study overheads when query compute is equal. Note this this affects
           accuracy. With our current setup, our responses are 93% accurate.
           You can increase the FIXEDCOMP or remove the following line to vary
           HDSearch's computations.*/
        point_ids_for_all_bucket_servers[i][0].resize(FIXEDCOMP);
    }
    // map_fine_mutex[unique_request_id_value]->lock();
    response_count_down_map[unique_request_id_value].index_reply->set_get_point_ids_time(GetTimeInMicro() - start_time);
    response_count_down_map[unique_request_id_value].index_reply->set_get_bucket_responses_time(GetTimeInMicro());
    // map_fine_mutex[unique_request_id_value]->unlock();

    long total_time = GetTimeInMicro() - beginning_time;

    printf("Full time taken: %ld\n", total_time);
    printf("Pre-Query Request Interval: %d\n", send_request_usecs_wait);
    // Increment process request count and store time taken
    ++process_request_count;
    times_taken.push_back(total_time);

    // Check if 1000 iterations have passed
    if (process_request_count % 1000 == 0 && send_request_usecs_wait >= 0 && adaptive)
    {
        // Calculate average time
        uint64_t total_time = 0;
        for (const auto &time : times_taken)
        {
            total_time += time;
        }
        uint64_t average_time = total_time / times_taken.size();

        // Adjust send_request_usecs_wait parameter based on comparison with previous average
        // If the pre-request interval increased previously, then increase it now (initially it will increase)
        if (increasing)
        {
            // If the new average is less, then increase the send_request_usecs_wait
            if (average_time < previous_average_time)
            {
                send_request_usecs_wait += step;
            }
            else // Decrease the send request time
            {
                send_request_usecs_wait -= step;
                increasing = false;
            }
        }
        else
        {
            // If the new average is less, then decrease the send_request_usecs_wait
            if (average_time < previous_average_time)
            {
                send_request_usecs_wait -= step;
            }
            else // Increase the send request time
            {
                send_request_usecs_wait += step;
                increasing = true;
            }
        }
        // Change the step (the rate which will increase or decrease the pre-query request interval)
        if (step > 5)
        {
            step /= 2;
        }
        previous_average_time = average_time;

        // Reset times_taken array for next 1000 iterations
        times_taken.clear();
    }

    for (int i = 0; i < number_of_bucket_servers; i++)
    {
        int index = (tid * number_of_bucket_servers) + i;
        bucket_connections[index]->GetNearestNeighbors(queries_multiple_points,
                                                       point_ids_for_all_bucket_servers[i],
                                                       queries_size,
                                                       number_of_nearest_neighbors,
                                                       i,
                                                       (dataset_size / number_of_bucket_servers),
                                                       util_present,
                                                       unique_request_id_value,
                                                       request_to_bucket);
    }
    e1 = GetTimeInMicro() - s1;
    response_count_down_map[unique_request_id_value].index_reply->set_index_time(e1);
    map_fine_mutex[unique_request_id_value]->unlock();

    // Don't send pre request after here
    sendRequestFlag.store(false, std::memory_order_release);
}

/* The request processing thread runs this
   function. It checks all the bucket socket connections one by
   one to see if there is a response. If there is one, it then
   implements the count down mechanism in the global map.*/
void ProcessResponses()
{
    while (true)
    {
        bucket_connections[0]->AsyncCompleteRpc();
    }
}

void FinalKill()
{
#if 0
            kill_notify.pop();
            long int sleep_time = 50 * 1000 * 1000;
            usleep(sleep_time);
            CHECK(false, "couldn't die, so timer killed it\n");
#endif
}

void Perf()
{
    while (true)
    {
        if (started->AtomicallyReadFlag())
        {
            std::cout << "cs\n";
            std::string s = "sudo perf stat -e cs -I 30000 -p " + std::to_string(getpid());
            char *cmd = new char[s.length() + 1];
            std::strcpy(cmd, s.c_str());
            ExecuteShellCommand(cmd);
            break;
        }
    }
}

void SysCount()
{
    while (true)
    {
        if (started->AtomicallyReadFlag())
        {
            std::cout << "syscnt\n";
            std::string s = "sudo /usr/share/bcc/tools/syscount -i 30 -p " + std::to_string(getpid()) + " > " + "syscount.txt";
            char *cmd = new char[s.length() + 1];
            std::strcpy(cmd, s.c_str());
            ExecuteShellCommand(cmd);
            std::cout << "executed syscount\n";
            break;
        }
    }
}

void Hardirqs()
{
    while (true)
    {
        if (started->AtomicallyReadFlag())
        {
            std::cout << "hardirqs\n";
            std::string s = "sudo /usr/share/bcc/tools/hardirqs -d -T 30 1 > hardirqs.txt";
            char *cmd = new char[s.length() + 1];
            std::strcpy(cmd, s.c_str());
            ExecuteShellCommand(cmd);
            break;
            std::cout << "executed hardirqs\n";
        }
    }
}

void Wakeuptime()
{
    while (true)
    {
        if (started->AtomicallyReadFlag())
        {
            std::string s = "sudo /usr/share/bcc/tools/wakeuptime -p " + std::to_string(getpid()) + " 30 > wakeuptime.txt";
            char *cmd = new char[s.length() + 1];
            ExecuteShellCommand(cmd);
            break;
        }
    }
}

void Softirqs()
{
    while (true)
    {
        if (started->AtomicallyReadFlag())
        {
            std::string s = "sudo /usr/share/bcc/tools/softirqs -T 30 1 -d > softirqs.txt";
            char *cmd = new char[s.length() + 1];
            std::strcpy(cmd, s.c_str());
            ExecuteShellCommand(cmd);
            break;
        }
    }
}

void Runqlat()
{
    while (true)
    {
        if (started->AtomicallyReadFlag())
        {
            std::string s = "sudo /usr/share/bcc/tools/runqlat 30 1 > runqlat.txt";
            char *cmd = new char[s.length() + 1];
            std::strcpy(cmd, s.c_str());
            ExecuteShellCommand(cmd);
            break;
        }
    }
}

void Hitm()
{
    while (true)
    {
        if (started->AtomicallyReadFlag())
        {
            std::string s = "sudo perf c2c record -p " + std::to_string(getpid());
            char *cmd = new char[s.length() + 1];
            std::strcpy(cmd, s.c_str());
            ExecuteShellCommand(cmd);
            break;
        }
    }
}

void Tcpretrans()
{
    while (true)
    {
        if (started->AtomicallyReadFlag())
        {
            std::string s = "sudo /usr/share/bcc/tools/tcpretrans -c -l > tcpretrans.txt";
            char *cmd = new char[s.length() + 1];
            std::strcpy(cmd, s.c_str());
            ExecuteShellCommand(cmd);
            break;
        }
    }
}

int main(int argc, char **argv)
{
    // Pre-request code
    int status, valread, client_fd2;
    struct sockaddr_in serv_addr1, serv_addr2;
    bool poisson, fixed, exponential, pre_request;
    pre_request = true; // atoi(argv[2]);

    char *hello = "Hello from client";
    char buffer[30] = {0};

    char *serv_addr_ip = "10.10.1.3";
    int sleep_usecs;
    int warmup_requests = 0;

    // Create socket for port 8080
    if ((client_fd1 = socket(AF_INET, SOCK_STREAM, 0)) < 0)
    {
        printf("\n Socket creation error for port 8080\n");
        return -1;
    }

    serv_addr1.sin_family = AF_INET;
    serv_addr1.sin_port = htons(PORT);

    // Convert IPv4 and IPv6 addresses from text to binary
    if (inet_pton(AF_INET, serv_addr_ip, &serv_addr1.sin_addr) <= 0)
    {
        printf("\nInvalid address/ Address not supported \n");
        return -1;
    }

    // Connect to port 8080
    if ((status = connect(client_fd1, (struct sockaddr *)&serv_addr1, sizeof(serv_addr1))) < 0)
    {
        printf("\nConnection Failed to port 8080\n");
        return -1;
    }

    signal(SIGPIPE, sigpipe_handler);
    long time_taken, total_time = 0;

    // Start the helper thread
    // std::thread helperThread(helperThreadFunction, client_fd1, hello, buffer, PORT);

    // End of pre-request code

    // Copying arguments

    // Calculate the number of arguments to copy
    // int numArgs = argc - 2;
    // // Dynamically allocate memory for the arguments
    // char **arguments = (char **)malloc(numArgs * sizeof(char *));
    // if (arguments == NULL)
    // {
    //     fprintf(stderr, "Memory allocation failed\n");
    //     return 1;
    // }

    // Copy arguments from argv[2] to arguments[]
    // for (int i = 0; i < numArgs; i++)
    // {
    //     // Dynamically allocate memory for each argument
    //     // For the first one, keep its place
    //     if (i == 0)
    //     {
    //         arguments[0] = (char *)malloc(strlen(argv[0]) + 1);
    //     }
    //     else
    //     {
    //         arguments[i] = (char *)malloc(strlen(argv[i + 2]) + 1);
    //     }

    //     if (arguments[i] == NULL)
    //     {
    //         fprintf(stderr, "Memory allocation failed\n");

    //         // Free memory allocated so far
    //         for (int j = 0; j < i; j++)
    //         {
    //             free(arguments[j]);
    //         }
    //         free(arguments);
    //         return 1;
    //     }

    //     // Copy argument
    //     if (i == 0)
    //     {
    //         strcpy(arguments[0], argv[0]);
    //     }
    //     else
    //     {
    //         strcpy(arguments[i], argv[i + 2]);
    //     }
    // }

    // Now, arguments[] contains the copies of argv[2] to argv[argc-1]

    std::string dataset_file_name;
    IndexServerCommandLineArgs *index_server_command_line_args = ParseIndexServerCommandLine(argc,
                                                                                             argv);
    num_hash_tables = index_server_command_line_args->num_hash_tables;
    hash_table_key_length = index_server_command_line_args->hash_table_key_length;
    num_multi_probe_levels = index_server_command_line_args->num_multi_probe_levels;
    number_of_bucket_servers = index_server_command_line_args->number_of_bucket_servers;
    std::string bucket_server_ips_file = index_server_command_line_args->bucket_server_ips_file;
    dataset_file_name = index_server_command_line_args->dataset_file_name;
    mode = index_server_command_line_args->mode;
    ip = index_server_command_line_args->ip;
    network_poller_parallelism = index_server_command_line_args->network_poller_parallelism;
    dispatch_parallelism = index_server_command_line_args->dispatch_parallelism;
    number_of_response_threads = index_server_command_line_args->number_of_async_response_threads;
    get_profile_stats = index_server_command_line_args->get_profile_stats;
    // Load bucket server IPs into a string vector
    GetBucketServerIPs(bucket_server_ips_file, &bucket_server_ips);

    /* Before server starts for the 1st time, construct index for dataset.
       Offline action*/
    // Read dataset file and create a dataset matrix.
    Matrix<unsigned char> dataset;
    if (mode == 1)
    {
        dataset = *(CreateDatasetFromTextFile(
            dataset_file_name,
            &dataset_size,
            &dataset_dimensions));
        dataset_multiple_points.CreateMultiplePoints(dataset_file_name);
    }
    else if (mode == 2)
    {
        CreateDatasetFromBinaryFile(
            dataset_file_name,
            &dataset_size,
            &dataset_dimensions,
            &dataset);
        CreateMultiplePointsFromBinaryFile(
            dataset_file_name,
            &dataset_multiple_points);
    }
    else
    {
        CHECK(false, "ERROR: Mode must be either 1 (text file) or 2 (binary file)\n");
    }

    /* Number of points in dataset must be >= number of bucket servers
       because we shard the dataset across several bucket servers".*/
    CHECK((dataset_size >= number_of_bucket_servers), "ERROR: Number of points in the dataset must be >= number of bucket servers");

    /* You can either build index from scratch here using BuildLshIndex
       or you can load index from file, using LoadLshIndexFromFile.
       Performance depends on size of the dataset.*/
    BuildLshIndex(dataset,
                  num_hash_tables,
                  hash_table_key_length,
                  num_multi_probe_levels,
                  &lsh_index);
    unsigned int shard_size = dataset_size / number_of_bucket_servers;
    lsh_index.ChangeTablesStructure(number_of_bucket_servers,
                                    shard_size,
                                    tables_of_vectors);
    for (int i = 0; i < dispatch_parallelism; i++)
    {
        for (unsigned int j = 0; j < number_of_bucket_servers; j++)
        {
            std::string ip = bucket_server_ips[j];
            bucket_connections.emplace_back(new DistanceServiceClient(grpc::CreateChannel(
                ip, grpc::InsecureChannelCredentials())));
        }
    }
    std::vector<std::thread> response_threads;
    for (int i = 0; i < number_of_response_threads; i++)
    {
        response_threads.emplace_back(std::thread(ProcessResponses));
    }

    // std::thread kill_ack = std::thread(FinalKill);
    // std::thread perf(Perf);
    // std::thread syscount(SysCount);
    // std::thread hardirqs(Hardirqs);
    // std::thread wakeuptime(Wakeuptime);
    // std::thread softirqs(Softirqs);
    // std::thread runqlat(Runqlat);
    // //std::thread hitm(Hitm);
    // std::thread tcpretrans(Tcpretrans);

    server = new ServerImpl();
    server->Run();
    for (unsigned int i = 0; i < number_of_response_threads; i++)
    {
        response_threads[i].join();
    }

    // kill_ack.join();
    // perf.join();
    // syscount.join();
    // hardirqs.join();
    // wakeuptime.join();
    // softirqs.join();
    // runqlat.join();
    // //hitm.join();
    // tcpretrans.join();
    return 0;
}