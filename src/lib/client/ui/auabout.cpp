//-+---+---+---+---+---+---+---+---+---|---+---+---+---+---+---+-==+---+---+---|---+---+---+---+---+---+---+---+---+---+---+---+---|
// $Id: auabout.cpp,v 1.18 2022/02/19 21:49:46 daveh Exp $
// Copyright (c) 2022 Hazeron Freehold LLC
// All rights reserved.
//-+---+---+---+---+---+---+---+---+---|---+---+---+---+---+---+-==+---+---+---|---+---+---+---+---+---+---+---+---+---+---+---+---|

#include "auabout.h"
//
#include "auapp.h"
#include "auglobal.h"
#include "austylesheet.h"
#include <QFile>
#include <QHBoxLayout>
#include <QLabel>
#include <QMessageBox>
#include <QPixmap>
#include <QTextBrowser>
#include <QToolButton>

AuAbout::AuAbout(QWidget* parent) : AuDialog(parent)
{
	setAuDlgTitle(tr("About %1").arg(g_Au.ApplicationName()));
	setAuDlgIcon(QIcon(auApp->Icon32()));

	QString slogan(auApp->Slogan());
	QString sicon(auApp->Icon128());

	QString copy;
	if(QString(AuUtil::CopyrightYear()) == QString("2022"))
		copy = QString("2022");
	else
		copy = QString("2022-%1").arg(AuUtil::CopyrightYear());

	// Use a browser widget for the rest so we can follow links and scroll. It's a lot of text.
	QString copyrights = tr("<html>"
			"<table><tbody>"

			"<tr><td style=\"text-align: center;\">"
			"<img src=\"qrc%7\" width=\"128\"><br>"
			"</td><td>"
			"<b><big><i>%5</i></big></b><br>"
			"<i><small>%2</small></i><p>"

			"<i>%6</i><p>"

			"<a href=\"https://openshores.net\" style=\"color: %4;\">openshores.net</a><p>"

			"OpenShores is an unofficial community project. "
			"It is not affiliated with or endorsed by Hazeron Freehold LLC."
			"</td></tr>"

			"</tbody></table>"

			// Give thanks to Deantwo.
			"<hr>"
			"<big><b>Thank You Deantwo!</b></big><br>"
			"Special thanks to Deantwo for endless patience helping players and all the work he does maintaining the wiki. "
			"at <a href=\"https://www.hazeron.com/wiki\" style=\"color: %4;\">Hazeron.com/wiki</a>. "
			"Deantwo has been a fantastic helper for many years. "
			"His work is voluntary; he doesn't get paid, just donates his time. "
			"Be sure to thank him when you see him and give him the respect he has earned. "

			"<hr>"
			"<big><b>Components</b></big><br>"
			"3rd party components are property of their respective owners; "
			"they reserve certain rights to their portions of this software."
			"<br>"
			"<table><tbody>"

			"<tr><td style=\"text-align: right;\">"
			"<img src=\"qrc:data/QtLogo.png\"><br>"
			"</td><td>"
			"<b><big>Qt</big></b><br>"
			"The Leading C++ Based Cross-Platform UI and Software Application Development Framework<br>"
			"Click the button below for information about <i>Qt</i>.<br>"
			"</td></tr>"

			"<tr><td style=\"text-align: right;\">"
			"<img src=\"qrc:data/OpenGLLogo.png\"><br>"
			"</td><td>"
			"<b><big>OpenGL</big></b><br>"
			"The Premier Environment for Developing Portable, Interactive 2D and 3D Graphics Applications<br>"
			"The Khronos Group<br>"
			"<a href=\"http://www.opengl.org\" style=\"color: %4;\">www.opengl.org</a><br>"
			"OpenGL is a registered trademark of SGI.<br>"
			"<a href=\"http://www.sgi.com\" style=\"color: %4;\">www.sgi.com</a><br>"
			"</td></tr>"

			"<tr><td style=\"text-align: right;\">"
			"<img src=\"qrc:data/OpenALLogo.png\"><br>"
			"</td><td>"
			"<b><big>OpenAL</big></b><br>"
			"Software Interface to Audio Hardware<br>"
			"<a href=\"http://www.openal.org\" style=\"color: %4;\">www.openal.org</a><br>"
			"Creative Technology Ltd.<br>"
			"<a href=\"http://us.creative.com\" style=\"color: %4;\">us.creative.com</a><br>"
			"</td></tr>"

			"<tr><td style=\"text-align: right;\">"
			"<img src=\"qrc:data/SDLLogo.png\"><br>"
			"</td><td>"
			"<b><big>SDL Simple Directmedia Layer</big></b><br>"
			"Provides Low Level Access to Audio, Keyboard, Mouse, Joystick, and Graphics Hardware<br>"
			"<a href=\"http://libsdl.org\" style=\"color: %4;\">libsdl.org</a><br>"
			"</td></tr>"

			"</tbody></table>"


			"<hr>"
			"<big><b>Shores of Hazeron</b></big><br>"
			"Copyright %1 %3 Hazeron Freehold LLC<br>"
			"Used under the Shores of Hazeron License; see the LICENSE file included with this software."
			"<p>"
			"Support the original author: "
			"<a href=\"https://store.steampowered.com/app/2239520/Hazeron_Starship/\" style=\"color: %4;\">"
			"Hazeron Starship on Steam</a>"

			"</html>")
			.arg(g_Au.CopyrightSymbol())
			.arg(AuUtil::VersionFull())
			.arg(copy)
			.arg(AuStyleSheet::HazeronButtonText().name())
			.arg(g_Au.ApplicationName())
			.arg(slogan)
			.arg(sicon);
	QTextBrowser* browser = new QTextBrowser(this);
	browser->setOpenExternalLinks(true);
	browser->setReadOnly(true);
	browser->setHtml(copyrights);

	QToolButton* qt = new QToolButton(this);
	qt->setIcon(QIcon(":data/QtLogo.png"));
	qt->setAutoRaise(true);
	qt->setToolTip(tr("<html><b>About <i>Qt</i>...</b><br>"
				"Shows information about <i>Qt</i>."
				"</html>"));
	connect(qt, SIGNAL(clicked(bool)), SLOT(AboutQt()));

	QToolButton* license = new QToolButton(this);
	license->setText(tr("License..."));
	license->setAutoRaise(true);
	license->setToolTip(tr("<html><b>License...</b><br>"
				"Shows the license terms for <i>%1</i>."
				"</html>").arg(g_Au.ApplicationName()));
	connect(license, SIGNAL(clicked(bool)), SLOT(ShowLicense()));

	QHBoxLayout* buttonLay = new QHBoxLayout;
	buttonLay->addWidget(qt);
	buttonLay->addWidget(license);
	//buttonLay->addStretch();

	QVBoxLayout* lay = new QVBoxLayout;
	lay->addWidget(browser);
	lay->addLayout(buttonLay);
	lay->setMargin(2);
	lay->setSpacing(2);
	setAuDlgLayout(lay);
}

AuAbout::~AuAbout()
{
}

QSize AuAbout::sizeHint() const
{
	return QSize(600,500);
}

void AuAbout::AboutQt()
{
	QMessageBox::aboutQt(this, tr("About Qt"));
}

void AuAbout::ShowLicense()
{
	QString licenseText;
	QFile file(":data/LICENSE.txt");
	if(file.open(QIODevice::ReadOnly))
		licenseText = QString::fromUtf8(file.readAll());
	else
		licenseText = tr("The license text could not be loaded. See the LICENSE file included with this software.");

	QString text = tr("OpenShores is an unofficial community continuation of Shores of Hazeron, "
			"used under the license of the original, reproduced below.");
	text += "\n\n";
	text += licenseText.trimmed();
	text += "\n\n";
	text += tr("This software includes third-party libraries, such as Qt, OpenAL Soft and SDL. "
			"They remain the property of their respective owners and are covered by their own licenses.");

	AuDialog dlg(this);
	dlg.setAuDlgTitle(tr("%1 License").arg(g_Au.ApplicationName()));
	dlg.setAuDlgIcon(QIcon(auApp->Icon32()));

	QTextBrowser* browser = new QTextBrowser(&dlg);
	browser->setReadOnly(true);
	browser->setPlainText(text);
	browser->setMinimumSize(560, 420);

	QVBoxLayout* lay = new QVBoxLayout;
	lay->addWidget(browser);
	lay->setMargin(2);
	lay->setSpacing(2);
	dlg.setAuDlgLayout(lay);
	dlg.exec();
}
