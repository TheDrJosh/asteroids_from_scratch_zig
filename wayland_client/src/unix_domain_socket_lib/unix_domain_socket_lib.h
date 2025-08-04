#include<stddef.h>
#include<stdint.h>

int send_fds_with_data(int socket_fd, int32_t* fds_to_send, size_t num_fds,
    const void* data, size_t data_len);

int recv_fds_with_data(int socket_fd, int* received_fds, size_t max_fds,
    void* data_buf, size_t buf_size, size_t* data_received);