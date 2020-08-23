//
//  File.swift
//  
//
//  Created by Boon eng on 2020/8/23.
//
import GRPC
import Nowaproto
import Logging
import NIO

// Quieten the logs.
LoggingSystem.bootstrap {
  var handler = StreamLogHandler.standardOutput(label: $0)
  handler.logLevel = .critical
  return handler
}

func getRestaurant(restaurantID: Int32?, client nowaClient: Nowaproto_NowaClient) {
  // Form the request with the name, if one was provided.
  let request = Nowaproto_GetRestaurantRequest.with {
    $0.restaurantID = restaurantID ?? 1
  }

  // Make the RPC call to the server.
  let getRestaurant = nowaClient.getRestaurant(request)

  // wait() on the response to stop the program from exiting before the response is received.
  do {
    let response = try getRestaurant.response.wait()
    print("Client received: \(response)")
  } catch {
    print("Client failed: \(error)")
  }
}

func main(args: [String]) {
  // arg0 (dropped) is the program name. We expect arg1 to be the port, and arg2 (optional) to be
  // the name sent in the request.
  let arg1 = args.dropFirst(1).first
  let arg2 = args.dropFirst(2).first

    switch (arg1.flatMap(Int.init), arg2.flatMap(Int32.init)) {
  case (.none, _):
    print("Usage: PORT [RESTAURANT_ID]")
    exit(1)

  case let (.some(port), restaurantID):
    // Setup an `EventLoopGroup` for the connection to run on.
    //
    // See: https://github.com/apple/swift-nio#eventloops-and-eventloopgroups
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    // Make sure the group is shutdown when we're done with it.
    defer {
      try! group.syncShutdownGracefully()
    }

    // Configure the channel, we're not using TLS so the connection is `insecure`.
    let channel = ClientConnection.insecure(group: group)
      .connect(host: "localhost", port: port)

    // Provide the connection to the generated client.
    let nowaClient = Nowaproto_NowaClient(channel: channel)

    // Do the greeting.
    getRestaurant(restaurantID: restaurantID, client: nowaClient)
  }
}

main(args: CommandLine.arguments)
