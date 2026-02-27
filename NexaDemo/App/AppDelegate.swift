import ImageKitIO
import UIKit

@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let configuration = ImageKitConfiguration.load()
        let publicKey = configuration?.publicKey ?? "your_public_api_key="
        let urlEndpoint = configuration?.urlEndpoint ?? "https://ik.imagekit.io/your_imagekit_id"

        _ = ImageKit(
            publicKey: publicKey,
            urlEndpoint: urlEndpoint,
            transformationPosition: .PATH,
            defaultUploadPolicy: UploadPolicy.Builder()
                .requireNetworkType(.ANY)
                .maxRetries(3)
                .build()
        )

        return true
    }
}
