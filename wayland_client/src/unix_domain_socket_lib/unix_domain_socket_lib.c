#include "unix_domain_socket_lib.h"
#include <sys/socket.h>
#include <string.h>
#include <stdio.h>

int send_fds_with_data(int socket_fd, int32_t* fds_to_send, size_t num_fds, const void* data, size_t data_len) {
    struct msghdr msg = { 0 };
    struct cmsghdr* cmsg;
    char control_buf[CMSG_SPACE(sizeof(int) * num_fds)];

    // Set up the data portion
    struct iovec iov = {
        .iov_base = (void*)data,
        .iov_len = data_len
    };

    msg.msg_iov = &iov;
    msg.msg_iovlen = 1;

    // Set up control message for file descriptors (if any)
    if (num_fds > 0 && fds_to_send != NULL) {
        msg.msg_control = control_buf;
        msg.msg_controllen = sizeof(control_buf);

        cmsg = CMSG_FIRSTHDR(&msg);
        cmsg->cmsg_level = SOL_SOCKET;
        cmsg->cmsg_type = SCM_RIGHTS;
        cmsg->cmsg_len = CMSG_LEN(sizeof(int) * num_fds);

        // Copy all file descriptors to the control message data
        memcpy(CMSG_DATA(cmsg), fds_to_send, sizeof(int) * num_fds);
    }
    else {
        msg.msg_control = NULL;
        msg.msg_controllen = 0;
    }

    if (sendmsg(socket_fd, &msg, 0) == -1) {
        perror("sendmsg");
        return -1;
    }

    return 0;
}

// Function to receive multiple file descriptors and data over a Unix domain socket
int recv_fds_with_data(int socket_fd, int* received_fds, size_t max_fds, void* data_buf, size_t buf_size, size_t* data_received) {
    struct msghdr msg = { 0 };
    struct cmsghdr* cmsg;
    char control_buf[CMSG_SPACE(sizeof(int) * max_fds)];

    struct iovec iov = {
        .iov_base = data_buf,
        .iov_len = buf_size
    };

    msg.msg_iov = &iov;
    msg.msg_iovlen = 1;
    msg.msg_control = control_buf;
    msg.msg_controllen = sizeof(control_buf);

    ssize_t bytes_received = recvmsg(socket_fd, &msg, 0);
    if (bytes_received == -1) {
        perror("recvmsg");
        return -1;
    }

    if (data_received) {
        *data_received = bytes_received;
    }

    // Check for file descriptors in control message
    cmsg = CMSG_FIRSTHDR(&msg);
    if (cmsg != NULL && cmsg->cmsg_level == SOL_SOCKET &&
        cmsg->cmsg_type == SCM_RIGHTS) {

        // Calculate how many file descriptors were received
        int num_fds = (cmsg->cmsg_len - CMSG_LEN(0)) / sizeof(int);

        if (num_fds > max_fds) {
            perror("Received more fds than expected");
            return -2;
        }

        // Copy all received file descriptors
        memcpy(received_fds, CMSG_DATA(cmsg), sizeof(int) * num_fds);

        return num_fds;
    }

    // No file descriptors received
    return 0;
}