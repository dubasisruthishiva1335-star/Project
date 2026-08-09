import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles, RolesGuard } from '../auth/roles.guard';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../common/storage.service';
import { ConfirmResultDto } from './dto/confirm-result.dto';

@ApiTags('admin-results')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN', 'SUPER_ADMIN')
@Controller('admin/results')
export class ResultsAdminController {
  constructor(private prisma: PrismaService, private storage: StorageService) {}

  @Post('confirm')
  async confirm(@Body() dto: ConfirmResultDto) {
    const sem = dto.semester ?? dto.year ?? 1;
    return this.prisma.result.create({
      data: {
        hallTicket: dto.hallTicket,
        semester: sem,
        s3Key: dto.s3Key,
        fileUrl: dto.publicUrl || this.storage.publicUrlFor(dto.s3Key),
      },
    });
  }
}
