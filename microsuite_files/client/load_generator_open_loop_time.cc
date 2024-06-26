/* Author: Akshitha Sriraman
   Ph.D. Candidate at the University of Michigan - Ann Arbor*/

#include <iostream>
#include <memory>
#include <random>
#include <stdlib.h>
#include <string>
#include <sys/time.h>

#include <grpc++/grpc++.h>
#include <thread>

#include "helper_files/mid_tier_client_helper.h"
#include "helper_files/timing.h"

#include "mid_tier_service/src/atomics.cpp"

// Pre-request code

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

using grpc::Channel;
using grpc::ClientAsyncResponseReader;
using grpc::ClientContext;
using grpc::CompletionQueue;
using grpc::Status;
using loadgen_index::LoadGenIndex;
using loadgen_index::LoadGenRequest;
using loadgen_index::ResponseIndexKnnQueries;

unsigned int number_of_bucket_servers = 0;
Atomics *num_requests = new Atomics();
Atomics *responses_recvd = new Atomics();
Atomics *util_requests = new Atomics();

float qps = 0.0;
std::string ip = "localhost";
bool resp_recvd = false, kill_ack = false;
std::string timing_file_name = "", qps_file_name = "";
std::map<uint64_t, uint64_t> resp_times;
uint64_t interval_start_time = GetTimeInSec();
UtilInfo *previous_util = new UtilInfo();
GlobalStats *global_stats = new GlobalStats();
std::mutex global_stat_mutex;
bool first_req_flag = false;
std::mutex cout_lock, kill_ack_lock;
int num_inline = 0, num_workers = 0, num_resp = 0;

#define NODEBUG

class LoadGenIndexClient
{
public:
    explicit LoadGenIndexClient(std::shared_ptr<Channel> channel)
        : stub_(LoadGenIndex::NewStub(channel)) {}

    // Assembles the client's payload and sends it to the server.
    void LoadGen_Index(MultiplePoints *queries,
                       const uint64_t query_id,
                       const unsigned &queries_size,
                       const unsigned &number_of_nearest_neighbors,
                       const bool util_request,
                       const bool kill)
    {
        uint64_t start = GetTimeInMicro();
        // Get the dimension
        int dimension = queries->GetPointAtIndex(0).GetSize();
        // Declare the set of queries & #NN that must be sent.
        LoadGenRequest load_gen_request;
        load_gen_request.set_kill(kill);

        // Create RCP request by adding queries and number of NN.
        CreateIndexServiceRequest(*queries,
                                  query_id,
                                  queries_size,
                                  number_of_nearest_neighbors,
                                  dimension,
                                  util_request,
                                  &load_gen_request);

        // Call object to store rpc data
        AsyncClientCall *call = new AsyncClientCall;
        // uint64_t request_id = reinterpret_cast<uintptr_t>(call);
        uint64_t request_id = num_requests->AtomicallyReadCount();
        load_gen_request.set_request_id(request_id);
        load_gen_request.set_load((int)(qps));
        resp_times[request_id] = GetTimeInMicro();
        call->index_reply.set_create_index_req_time(GetTimeInMicro() - start);

        /* A.S The following line work if you want
           to invoke acuracy script.*/
        // cout_lock.lock();
        // std::cout << request_id << " q " << query_id << std::endl;
        // cout_lock.unlock();

        // stub_->AsyncSayHello() performs the RPC call, returning an instance to
        // store in "call". Because we are using the asynchronous API, we need to
        // hold on to the "call" instance in order to get updates on the ongoing RPC.
#ifndef NODEBUG
        std::cout << "before sending req\n";
#endif
        try
        {
            call->response_reader = stub_->AsyncLoadGen_Index(&call->context, load_gen_request, &cq_);

            // Request that, upon completion of the RPC, "reply" be updated with the
            // server's response; "status" with the indication of whether the operation
            // was successful. Tag the request with the memory address of the call object.
            call->response_reader->Finish(&call->index_reply, &call->status, (void *)call);
        }
        catch (...)
        {
            std::cout << "Load generator failed ";
            CHECK(false, "");
        }
#ifndef NODEBUG
        std::cout << "after sending req\n";
#endif
    }

    // Loop while listening for completed responses.
    // Prints out the response from the server.
    void AsyncCompleteRpc()
    {
        void *got_tag;
        bool ok = false;
        // std::string timing_file_name_final = timing_file_name + std::to_string(qps) + ".txt";
        // std::ofstream timing_file;
        //  Block until the next result is available in the completion queue "cq".
        while (cq_.Next(&got_tag, &ok))
        {
            // timing_file.open(timing_file_name_final, std::ios_base::app);
            //  The tag in this example is the memory location of the call object
            AsyncClientCall *call = static_cast<AsyncClientCall *>(got_tag);

            // Verify that the request was completed successfully. Note that "ok"
            // corresponds solely to the request for updates introduced by Finish().
            // GPR_ASSERT(ok);

            if (call->status.ok())
            {
#ifndef NODEBUG
                std::cout << "got resp\n";
#endif
                kill_ack_lock.lock();
                if (call->index_reply.kill_ack())
                {
                    kill_ack = true;
                    std::cout << "got kill ack\n";
                    std::cout << std::flush;
                }
                kill_ack_lock.unlock();

                if (util_requests->AtomicallyReadCount() == 1 && !first_req_flag)
                {
                    first_req_flag = true;
                    number_of_bucket_servers = call->index_reply.number_of_bucket_servers();
                    previous_util->bucket_util = new Util[number_of_bucket_servers];
                    global_stats->percent_util_info.bucket_util_percent = new PercentUtil[number_of_bucket_servers];
                }

                uint64_t request_id = call->index_reply.request_id();
                resp_times[request_id] = GetTimeInMicro() - resp_times[request_id];
                resp_recvd = true;
                uint64_t start_time, end_time;
                DistCalc knn_answer;
                TimingInfo *timing_info = new TimingInfo();
                PercentUtilInfo *percent_util_info = new PercentUtilInfo();
                percent_util_info->bucket_util_percent = new PercentUtil[number_of_bucket_servers];
                start_time = GetTimeInMicro();
                UnpackIndexServiceResponse(call->index_reply,
                                           &knn_answer,
                                           timing_info,
                                           previous_util,
                                           percent_util_info);
                end_time = GetTimeInMicro();
                timing_info->unpack_index_resp_time = end_time - start_time;
                timing_info->create_index_req_time = call->index_reply.create_index_req_time();
                timing_info->update_index_util_time = call->index_reply.update_index_util_time();
                timing_info->get_bucket_responses_time = call->index_reply.get_bucket_responses_time();
                /*WriteKNNToFile("/home/liush/highdimensionalsearch/results/async_results.txt",
                  knn_answer);*/
                timing_info->total_resp_time = resp_times[request_id];

                resp_times[request_id] = 0;
                // std::cout << timing_info->total_resp_time << std::endl;
                //  std::cout << timing_info->total_resp_time << " " << timing_info->get_bucket_responses_time << "\n";
                global_stat_mutex.lock();
                UpdateGlobalTimingStats(*timing_info,
                                        global_stats);
                global_stat_mutex.unlock();
                if ((util_requests->AtomicallyReadCount() != 1) && (call->index_reply.util_response().util_present()))
                {
                    UpdateGlobalUtilStats(percent_util_info,
                                          number_of_bucket_servers,
                                          global_stats);
                }
                // WriteTimingInfoToFile(timing_file, *timing_info);

                /* A.S The following two lines work if you want
                   to invoke acuracy script.*/
#if 0
                    cout_lock.lock();
                    std::cout << request_id << " ";
                    PrintKNNForAllQueries(knn_answer);
                    cout_lock.unlock();
#endif

                responses_recvd->AtomicallyIncrementCount();
                if (responses_recvd->AtomicallyReadCount() == 1)
                {
                    // Print the index config that we got this data for.
                    std::cout << call->index_reply.num_inline() << " " << call->index_reply.num_workers() << " " << call->index_reply.num_resp() << " ";
                }
            }
            else
            {
                sleep(2);
                std::string s = "./kill_index_server_empty " + ip;
                char *cmd = new char[s.length() + 1];
                std::strcpy(cmd, s.c_str());
                ExecuteShellCommand(cmd);
                std::cout << "Call Status Error Code: " << call->status.error_code() << "\n";
                std::cout << "Call Status Error Message: " << call->status.error_message() << "\n";
                std::cout << "Call Status Error Details: " << call->status.error_details() << "\n";
                std::cout << "Load generator failed\n";
                CHECK(false, "");
            }

            // Once we're complete, deallocate the call object.
            delete call;
        }
    }

private:
    // struct for keeping state and data information
    struct AsyncClientCall
    {
        // Container for the data we expect from the server.
        ResponseIndexKnnQueries index_reply;

        // Context for the client. It could be used to convey extra information to
        // the server and/or tweak certain RPC behaviors.
        ClientContext context;

        // Storage for the status of the RPC upon completion.
        Status status;

        std::unique_ptr<ClientAsyncResponseReader<ResponseIndexKnnQueries>> response_reader;
    };

    // Out of the passed in Channel comes the stub, stored here, our view of the
    // server's exposed services.
    std::unique_ptr<LoadGenIndex::Stub> stub_;

    // The producer-consumer queue we use to communicate asynchronously with the
    // gRPC runtime.
    CompletionQueue cq_;
};

int main(int argc, char **argv)
{
    // Pre-request code

    int status, valread, client_fd1, client_fd2;
    struct sockaddr_in serv_addr1, serv_addr2;
    bool poisson, fixed, exponential, pre_request;
    char *hello = "Hello from client";
    char buffer[30] = {0};

    char *serv_addr_ip = "10.10.1.2";
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
    // End of pre-request code

    /* Get path to queries (batch/single) and the number of
       nearest neighbors via the command line.*/
    unsigned int number_of_nearest_neighbors = 0;
    std::string queries_file_name, result_file_name;
    struct LoadGenCommandLineArgs *load_gen_command_line_args = new struct LoadGenCommandLineArgs();
    load_gen_command_line_args = ParseLoadGenCommandLine(argc,
                                                         argv);
    queries_file_name = load_gen_command_line_args->queries_file_name;
    result_file_name = load_gen_command_line_args->result_file_name;
    number_of_nearest_neighbors = load_gen_command_line_args->number_of_nearest_neighbors;
    uint64_t time_duration = load_gen_command_line_args->time_duration;
    qps = load_gen_command_line_args->qps;
    ip = load_gen_command_line_args->ip;
    qps_file_name = load_gen_command_line_args->qps_file_name;
    timing_file_name = load_gen_command_line_args->timing_file_name;
    std::string util_file_name = load_gen_command_line_args->util_file_name;
    CHECK((time_duration >= 0), "ERROR: Offered load (time in seconds) must always be a positive value");
    struct TimingInfo timing_info;
    // Create queries from query file.
    MultiplePoints queries;
    uint64_t start_time, end_time;
    start_time = GetTimeInMicro();
    CreatePointsFromBinFile(queries_file_name, &queries);
    end_time = GetTimeInMicro();
    timing_info.create_queries_time = end_time - start_time;
    long queries_size = queries.GetSize();

    // Instantiate the client. It requires a channel, out of which the actual RPCs
    // are created. This channel models a connection to an endpoint (in this case,
    // localhost at port 50051). We indicate that the channel isn't authenticated
    // (use of InsecureChannelCredentials()).
    std::string ip_port = ip;
    LoadGenIndexClient loadgen_index(grpc::CreateChannel(
        ip_port, grpc::InsecureChannelCredentials()));

    // Spawn reader thread that loops indefinitely
    std::thread thread_ = std::thread(&LoadGenIndexClient::AsyncCompleteRpc, &loadgen_index);
    // std::thread thread2 = std::thread(&LoadGenIndexClient::AsyncCompleteRpc, &loadgen_index);
    int index = rand() % queries_size;

    MultiplePoints query(1, queries.GetPointAtIndex(index));
    double center = 1000000.0 / (double)(100); // (100 QPS = 10ms interval)
    double curr_time = (double)GetTimeInMicro();
    // warmup for 15 second and 1000 qps
    double exit_time = curr_time + (double)(15 * 1000000);
    uint64_t overall_queries = 1000 * 15;

    // Declare the poisson distribution
    std::default_random_engine generator;
    // CHANGE
    std::poisson_distribution<int> distribution(center);
    double next_time = distribution(generator) + curr_time; // curr_time + center;

    //!!!!!!!WarmUp Phase!!!!!!

    while (responses_recvd->AtomicallyReadCount() < overall_queries)
    {
        if (curr_time >= next_time && num_requests->AtomicallyReadCount() < overall_queries)
        {
            num_requests->AtomicallyIncrementCount();
            /* If this is the first request, we must gather util info
               so that we can track util periodically after every 10 seconds.*/
            /* Before sending every request, we check to see if
               the time (10 sec) has expired, so that we can decide to
               fill the util_request field to get the util info from
               buckets and index. Otherwise, we do not request
               for util info (false).*/
            if ((num_requests->AtomicallyReadCount() == 1) || ((GetTimeInSec() - interval_start_time) >= 5))
            {
                util_requests->AtomicallyIncrementCount();
                loadgen_index.LoadGen_Index(&query,
                                            index,
                                            query.GetSize(),
                                            number_of_nearest_neighbors,
                                            true,
                                            false);
                interval_start_time = GetTimeInSec();
            }
            else
            {
                loadgen_index.LoadGen_Index(&query,
                                            index,
                                            query.GetSize(),
                                            number_of_nearest_neighbors,
                                            false,
                                            false);
            }
            // CHANGE
            next_time = distribution(generator) + curr_time; // curr_time + center;
            printf("Next Poisson time = %lf\n", next_time);
            index = rand() % queries_size;

            query.SetPoint(0, queries.GetPointAtIndex(index));
        }
        curr_time = (double)GetTimeInMicro();
    }

    // Reset timing statistics
    ResetMetaStats(global_stats, number_of_bucket_servers);
    // Reset requests counters
    num_requests->AtomicallyResetCount();
    responses_recvd->AtomicallyResetCount();
    // Validating by printing counters
    std::cout << "# Requests: " << num_requests->AtomicallyReadCount() << " \n";
    std::cout << "# Responses: " << responses_recvd->AtomicallyReadCount() << " \n";
    std::cout << "!!!!!!!End of Warmup Period!!!!!!!"
              << " \n";

    // std::uniform_int_distribution<> distribution_run(center);

    printf("Experiment duration: %lu\n", time_duration);

    exponential = false;
    center = 1000000.0 / (double)(qps);
    // Declare the poisson distribution
    std::default_random_engine generator_run;
    std::exponential_distribution<double> distribution_run((double)qps / 1000000);
    // CHANGE
    // std::poisson_distribution<int> distribution_run(center);
    curr_time = (double)GetTimeInMicro();
    exit_time = curr_time + (double)(time_duration * 1000000);
    if (exponential)
    {
        next_time = curr_time + distribution_run(generator_run);
    }
    else
    {
        next_time = curr_time + center; // distribution_run(generator_run) + curr_time;
    }

    // The next time is the current + center
    index = rand() % queries_size;
    //!!!!!!!Actual Run !!!!!!!
    printf("Next Exponential time = %lf\n", next_time);

    // OLD IMPLEMENTATION

    // while (curr_time < exit_time)
    // {
    //     if (curr_time >= next_time)
    //     {
    //         num_requests->AtomicallyIncrementCount();
    //         /* If this is the first request, we must gather util info
    //            so that we can track util periodically after every 10 seconds.*/
    //         /* Before sending every request, we check to see if
    //            the time (10 sec) has expired, so that we can decide to
    //            fill the util_request field to get the util info from
    //            buckets and index. Otherwise, we do not request
    //            for util info (false).*/
    //         if((num_requests->AtomicallyReadCount() == 1) || ((GetTimeInSec() - interval_start_time) >= 5)){
    //             util_requests->AtomicallyIncrementCount();
    //             loadgen_index.LoadGen_Index(&query,
    //                     index,
    //                     query.GetSize(),
    //                     number_of_nearest_neighbors,
    //                     true,
    //                     false);
    //             interval_start_time = GetTimeInSec();
    //         } else {
    //             loadgen_index.LoadGen_Index(&query,
    //                     index,
    //                     query.GetSize(),
    //                     number_of_nearest_neighbors,
    //                     false,
    //                     false);
    //         }
    //         // CHANGE
    //         next_time = curr_time + center; // distribution_run(generator_run) + curr_time;
    //         printf("Curr time = %lf\n", curr_time);
    //         printf("Next time = %lf\n", next_time);
    //         index = rand() % queries_size;

    //         query.SetPoint(0, queries.GetPointAtIndex(index));
    //     }
    //     curr_time = (double)GetTimeInMicro();
    // }

    // NEW IMPLEMENTATION (with sleep)
    pre_request = false;

    while (curr_time < exit_time)
    {
        // If it's set to send a pre-request, then send a pre-request to wake up
        if (pre_request)
        {
            time_taken = send_request(false, client_fd1, hello, buffer, 8080);
        }
        usleep(next_time - curr_time); // Sleep for (next_time - curr_time) microseconds, and then proceed
        curr_time = (double)GetTimeInMicro();

        // Send the actual request
        if (curr_time >= next_time)
        {
            num_requests->AtomicallyIncrementCount();
            /* If this is the first request, we must gather util info
               so that we can track util periodically after every 10 seconds.*/
            /* Before sending every request, we check to see if
               the time (10 sec) has expired, so that we can decide to
               fill the util_request field to get the util info from
               buckets and index. Otherwise, we do not request
               for util info (false).*/
            if ((num_requests->AtomicallyReadCount() == 1) || ((GetTimeInSec() - interval_start_time) >= 5))
            {
                util_requests->AtomicallyIncrementCount();
                loadgen_index.LoadGen_Index(&query,
                                            index,
                                            query.GetSize(),
                                            number_of_nearest_neighbors,
                                            true,
                                            false);
                interval_start_time = GetTimeInSec();
            }
            else
            {
                loadgen_index.LoadGen_Index(&query,
                                            index,
                                            query.GetSize(),
                                            number_of_nearest_neighbors,
                                            false,
                                            false);
            }
            // CHANGE
            if (exponential)
            {
                next_time = curr_time + distribution_run(generator_run);
            }
            else
            {
                next_time = curr_time + center; // distribution_run(generator_run) + curr_time;
            }

            printf("Curr time = %lf\n", curr_time);
            // printf("Next time = %lf\n", next_time);
            index = rand() % queries_size;

            query.SetPoint(0, queries.GetPointAtIndex(index));
        }
    }
    /*std::string qps_file_name_final = qps_file_name + std::to_string(qps) + ".txt";
      std::ofstream qps_file(qps_file_name_final);
      CHECK(qps_file.good(), "ERROR: Could not open QPS file.\n");
      qps_file << qps_to_file << "\n";
      qps_file.close();*/

    std::cout << "End of Actual Run"
              << "\n";
    float achieved_qps = (float)responses_recvd->AtomicallyReadCount() / (float)time_duration;
    // num_requests->AtomicallyIncrementCount();
    // responses_recvd->AtomicallyReadCount();
    std::cout << "# Requests: " << num_requests->AtomicallyReadCount() << " \n";
    std::cout << "# Responses: " << responses_recvd->AtomicallyReadCount() << " \n";
    std::cout << "Achieved QPS: " << achieved_qps << " \n";

    global_stat_mutex.lock();
#if 0
    PrintGlobalStats(*global_stats,
            number_of_bucket_servers,
            (util_requests->AtomicallyReadCount()-1),
            responses_recvd->AtomicallyReadCount());
#endif
    PrintLatency(*global_stats,
                 number_of_bucket_servers,
                 (util_requests->AtomicallyReadCount() - 1),
                 responses_recvd->AtomicallyReadCount());
    PrintGlobalStats(*global_stats,
                     number_of_bucket_servers,
                     (util_requests->AtomicallyReadCount() - 1),
                     responses_recvd->AtomicallyReadCount());
#if 0
    PrintUtil(*global_stats,
            number_of_bucket_servers,
            (util_requests-1));
    global_stat_mutex.unlock();
#endif
    /*WriteToUtilFile(util_file_name,
     *global_stats,
     number_of_bucket_servers,
     (util_requests-1));*/
    float query_cost = ComputeQueryCost(*global_stats,
                                        (util_requests->AtomicallyReadCount() - 1),
                                        number_of_bucket_servers,
                                        achieved_qps);
    global_stat_mutex.unlock();
    std::cout << " " << query_cost << std::endl;

    // std::cout << "kill start\n";
    // std::cout << std::flush;

    while (true)
    {
        // std::cout << "trying to send kill\n";
        std::cout << std::flush;
        kill_ack_lock.lock();
        if (kill_ack)
        {
            // std::cout << "got kill ack dying\n";
            // std::cout << std::flush;
            CHECK(false, "");
        }
        kill_ack_lock.unlock();
        sleep(2);
        loadgen_index.LoadGen_Index(&query,
                                    index,
                                    query.GetSize(),
                                    number_of_nearest_neighbors,
                                    false,
                                    true);
        // std::cout << "sent kill\n";
        // std::cout << std::flush;
    }

#if 0
    std::string s = "/home/liush/highdimensionalsearch/load_generator/kill_index_server_empty " + ip;
    char* cmd = new char[s.length() + 1];
    std::strcpy(cmd, s.c_str());
    ExecuteShellCommand(cmd);
    std::cout << "kill sent\n";
    std::cout << std::flush;
#endif

    CHECK(false, "Load generator exiting\n");
    thread_.join(); // blocks forever
    // thread2.join();

    return 0;
}