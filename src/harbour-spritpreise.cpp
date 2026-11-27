#include <sailfishapp.h>

#include <QGuiApplication>
#include <QQuickView>
#include <QQmlEngine>
#include <QQmlNetworkAccessManagerFactory>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QScopedPointer>

// QML's XMLHttpRequest may not set User-Agent itself. Nominatim's usage
// policy requires an identifying one, so every request from QML gets it here.
class UserAgentNam : public QNetworkAccessManager
{
public:
    explicit UserAgentNam(QObject *parent) : QNetworkAccessManager(parent) {}

protected:
    QNetworkReply *createRequest(Operation op, const QNetworkRequest &request,
                                 QIODevice *outgoingData) override
    {
        QNetworkRequest req(request);
        req.setRawHeader("User-Agent", "harbour-spritpreise/0.1.1 (SailfishOS)");
        return QNetworkAccessManager::createRequest(op, req, outgoingData);
    }
};

class UserAgentNamFactory : public QQmlNetworkAccessManagerFactory
{
public:
    QNetworkAccessManager *create(QObject *parent) override
    {
        return new UserAgentNam(parent);
    }
};

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    app->setOrganizationName(QStringLiteral("org.spritpreise"));
    app->setApplicationName(QStringLiteral("harbour-spritpreise"));

    // Declared before the view so it outlives the QML engine.
    UserAgentNamFactory namFactory;

    QScopedPointer<QQuickView> view(SailfishApp::createView());
    view->engine()->setNetworkAccessManagerFactory(&namFactory);
    view->setSource(SailfishApp::pathToMainQml());
    view->show();

    return app->exec();
}
