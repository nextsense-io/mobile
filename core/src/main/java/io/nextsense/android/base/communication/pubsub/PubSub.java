package io.nextsense.android.base.communication.pubsub;

import android.util.Log;

import com.google.api.core.ApiFuture;
import com.google.api.core.ApiFutureCallback;
import com.google.api.core.ApiFutures;
import com.google.cloud.pubsub.v1.Publisher;
import com.google.cloud.pubsub.v1.TopicAdminClient;
import com.google.common.util.concurrent.MoreExecutors;
import com.google.protobuf.ByteString;
import com.google.pubsub.v1.Encoding;
import com.google.pubsub.v1.PubsubMessage;
import com.google.pubsub.v1.TopicName;

import java.io.IOException;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;

import io.nextsense.android.base.Util;
import io.nextsense.android.base.data.Sample;

/**
 *
 */
public class PubSub {

  private static final String TAG = PubSub.class.getSimpleName();
  private static final String TOPIC_ID_DATA = "";
  private static final String DEFAULT_GCP_PROJECT = "nextsense-dev";

  private Publisher publisher;
  private Encoding encoding;

  public void init() throws IOException {
    publisher = Publisher.newBuilder(TOPIC_ID_DATA).build();
    TopicName topicName = TopicName.of(DEFAULT_GCP_PROJECT, TOPIC_ID_DATA);
    // Get the topic encoding type.
    try (TopicAdminClient topicAdminClient = TopicAdminClient.create()) {
      encoding = topicAdminClient.getTopic(topicName).getSchemaSettings().getEncoding();
    }
  }

  public void close() {
    if (publisher != null) {
      publisher.shutdown();
      try {
        publisher.awaitTermination(1, TimeUnit.MINUTES);
      } catch (InterruptedException e) {
        Log.w(TAG, "Interruped while closing the PubSub client: " + e.getMessage());
        Thread.currentThread().interrupt();
      }
    }
  }

  public void publishData(Sample sample) throws ExecutionException, InterruptedException {
    // Instantiate a protoc-generated class defined in `us-states.proto`.
    // State state = State.newBuilder().setName("Alaska").setPostAbbr("AK").build();

    try {
      PubsubMessage.Builder message = PubsubMessage.newBuilder();

      // Prepare an appropriately formatted message based on topic encoding.
//      switch (encoding) {
//        case BINARY:
//          message.setData(state.toByteString());
//          System.out.println("Publishing a BINARY-formatted message:\n" + message);
//          break;
//
//        case JSON:
//          String jsonString = JsonFormat.printer().omittingInsignificantWhitespace().print(state);
//          message.setData(ByteString.copyFromUtf8(jsonString));
//          System.out.println("Publishing a JSON-formatted message:\n" + message);
//          break;
//
//        default:
//          break;
//      }

      // Publish the message.
      ApiFuture<String> messageIdFuture = publisher.publish(message.build());
      ApiFutures.addCallback(messageIdFuture, new ApiFutureCallback<String>() {
        public void onSuccess(String messageId) {
          Util.logv(TAG, "Published message ID: " + messageId);
          // TODO(eric): Mark that segment in the database as sent.
        }

        public void onFailure(Throwable t) {
          // TODO(eric): Mark that segment in the database as not sent.
        }
      }, MoreExecutors.directExecutor());

    } finally {
      if (publisher != null) {
        publisher.shutdown();
        publisher.awaitTermination(1, TimeUnit.MINUTES);
      }
    }
  }
}
