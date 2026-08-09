import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles, RolesGuard } from '../auth/roles.guard';
import { PrismaService } from '../prisma/prisma.service';
import { CreateAptitudeDto } from './dto/create-aptitude.dto';

// Text-only domain: no file, so this skips the presign/upload flow
// entirely and the admin-web UploadForm renders with requireFile: false.
@ApiTags('admin-aptitude')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN', 'SUPER_ADMIN')
@Controller('admin/aptitude')
export class AptitudeAdminController {
  constructor(private prisma: PrismaService) {}

  @Post('confirm')
  confirm(@Body() dto: CreateAptitudeDto) {
    return this.prisma.aptitudeQuestion.create({ data: dto });
  }
}
