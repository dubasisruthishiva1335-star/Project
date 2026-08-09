import { Body, Controller, Post, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { IsString } from 'class-validator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles, RolesGuard } from '../auth/roles.guard';
import { PrismaService } from '../prisma/prisma.service';

class RegisterDeviceDto {
  @IsString() token: string;
  @IsString() platform: string;
}

class SendNotificationDto {
  @IsString() title: string;
  @IsString() body: string;
  // In production this fans out via SNS -> FCM; here it just logs, so the
  // endpoint shape (and the Admin Web page that calls it) is already correct
  // once real Firebase/SNS credentials are wired in.
}

@ApiTags('notifications')
@Controller('notifications')
export class NotificationsController {
  constructor(private prisma: PrismaService) {}

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post('register-device')
  async registerDevice(@Req() req: any, @Body() dto: RegisterDeviceDto) {
    return this.prisma.deviceToken.upsert({
      where: { token: dto.token },
      update: { platform: dto.platform, userId: req.user.sub },
      create: { token: dto.token, platform: dto.platform, userId: req.user.sub },
    });
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN', 'SUPER_ADMIN')
  @Post('send')
  async send(@Body() dto: SendNotificationDto) {
    const deviceCount = await this.prisma.deviceToken.count();
    // eslint-disable-next-line no-console
    console.log(`[notifications] Would send "${dto.title}" to ${deviceCount} devices via FCM.`);
    return { queued: true, targetDevices: deviceCount };
  }
}
